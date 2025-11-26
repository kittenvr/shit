import paho.mqtt.client as mqtt
import os
import time

# --- Hardcoded MQTT settings ---
BROKER = "locohost"        # change to your MQTT broker IP or hostname
PORT = 1883
TOPIC_REQUEST = "proxyfinder/request"
TOPIC_RESPONSE = "proxyfinder/response"
BEST_FILE = "/data/best_proxies.txt"
# -------------------------------
def on_connect(client, userdata, flags, reasonCode, properties):
    print(f"[*] Connected to MQTT broker {BROKER}:{PORT} (reasonCode={reasonCode})")
    client.subscribe(TOPIC_REQUEST)

def on_message(client, userdata, msg):
    print(f"[*] Received MQTT message on {msg.topic}: {msg.payload.decode().strip()}")
    # Respond with current proxy list whenever a message is received
    if os.path.exists(BEST_FILE):
        with open(BEST_FILE, "r") as f:
            data = f.read().strip() or "No proxies available yet."
    else:
        data = "Proxy list not found."
    client.publish(TOPIC_RESPONSE, data)
    print("[*] Sent proxy list via MQTT")

def main():
    # Create MQTT client using MQTT v5
    client = mqtt.Client(client_id="", protocol=mqtt.MQTTv5)
    client.on_connect = on_connect
    client.on_message = on_message

    while True:
        try:
            client.connect(BROKER, PORT, 60)
            client.loop_forever()
        except Exception as e:
            print(f"[!] MQTT connection error: {e}. Retrying in 10s...")
            time.sleep(10)

if __name__ == "__main__":
    main()
