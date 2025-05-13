"""
Listens for a single *combined* order that includes:
    • liters        – amount to fill
    • temperature   – target temperature
    • line          – which filling line to use

Orders are expected as JSON on the topic  `request/process`.
"""
import json
from queue import Queue
from typing import Dict

from mqtt.mqtt_connector import mqtt_connector

REQUEST_TOPIC = "request/process"


class mqtt_watcher:
    """Waits for incoming orders and hands them back as dictionaries."""

    def __init__(self, connector: mqtt_connector):
        self._connector = connector
        self._orders: Queue[Dict] = Queue()

        # Subscribe once – this topic carries the entire order
        self._connector.subscribe(REQUEST_TOPIC, qos=1)
        self._connector.register_callback(self._on_message)

    def _on_message(self, client, userdata, msg):
        if msg.topic != REQUEST_TOPIC:
            return
        try:
            order = json.loads(msg.payload.decode())
        except json.JSONDecodeError:
            return

        # Basic schema validation
        if all(k in order for k in ("liters", "temperature", "line")):
            self._orders.put(order)

    def wait_for_order(self) -> Dict:
        """Block until the next valid order arrives."""
        return self._orders.get(block=True)
