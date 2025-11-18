#!/usr/bin/env python3

import uvicorn
from fastapi import FastAPI
from pydantic import BaseModel
import pyperclip
import time
import threading
import json
from typing import List, Optional


# ------------------------------------------------------------
# OpenAI-Compatible Request Schema
# ------------------------------------------------------------
class Message(BaseModel):
    role: str
    content: str


class ChatCompletionRequest(BaseModel):
    model: str
    messages: List[Message]
    max_tokens: Optional[int] = None
    temperature: Optional[float] = None
    top_p: Optional[float] = None
    stream: Optional[bool] = False


# ------------------------------------------------------------
# Internal State for Clipboard Sync
# ------------------------------------------------------------
last_request_text = ""
pending_response = None
response_ready_event = threading.Event()


def clipboard_listener():
    """
    Background thread:
    Watches clipboard for pasted AI responses.
    When user copies a response, if waiting, it's accepted.
    """
    global pending_response

    prev = ""
    while True:
        time.sleep(0.2)
        current = pyperclip.paste()

        # Ignore if clipboard hasn't changed or matches outgoing request
        if current == prev or current == last_request_text:
            continue

        prev = current

        # Accept incoming response only when request is waiting
        if not response_ready_event.is_set():
            pending_response = current
            response_ready_event.set()


# Start clipboard watcher thread
threading.Thread(target=clipboard_listener, daemon=True).start()


# ------------------------------------------------------------
# FastAPI App
# ------------------------------------------------------------
app = FastAPI(title="Local OpenAI Clipboard Proxy")


@app.post("/v1/chat/completions")
async def chat_completions(req: ChatCompletionRequest):
    global last_request_text, pending_response

    # Build a text version of the model's incoming prompt
    conversation = "\n".join(f"{m.role}: {m.content}" for m in req.messages)

    # Store outgoing request to clipboard
    last_request_text = conversation
    pyperclip.copy(conversation)

    print("\n-----------------------------------------")
    print("📋 Request copied to clipboard.")
    print("Paste into ANY AI chat (ChatGPT, Claude, DeepSeek...).")
    print("Then copy the AI's response back to clipboard.")
    print("-----------------------------------------\n")

    # Wait for clipboard response
    response_ready_event.clear()
    pending_response = None
    response_ready_event.wait()

    ai_text = pending_response

    # Produce an OpenAI-style JSON-compatible response
    return {
        "id": "clipboard-proxy-response",
        "object": "chat.completion",
        "model": req.model,
        "choices": [
            {
                "index": 0,
                "finish_reason": "stop",
                "message": {
                    "role": "assistant",
                    "content": ai_text
                }
            }
        ]
    }


# ------------------------------------------------------------
# Entry point
# ------------------------------------------------------------
if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=5005)
