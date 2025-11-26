FROM python:3.12-slim

RUN apt-get update && apt-get install -y \
    curl iputils-ping gcc \
    && rm -rf /var/lib/apt/lists/*

RUN pip install proxybroker2 paho-mqtt

WORKDIR /app
COPY auto_find_best_proxies.sh entrypoint.sh mqtt_listener.py /app/
RUN chmod +x /app/auto_find_best_proxies.sh /app/entrypoint.sh

VOLUME ["/data"]
ENTRYPOINT ["/app/entrypoint.sh"]
