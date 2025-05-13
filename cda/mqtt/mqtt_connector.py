from __future__ import annotations
import threading
from typing import Callable, List, Any
import paho.mqtt.client as mqtt
from urllib.parse import urlparse
import ssl

class mqtt_connector:

    def __init__(
        self,
        broker_url: str = "wss://mosquitto.waterguys.dk:443/",
    ) -> None:
        print(f"MQTT: Initialising connector for {broker_url}")
        parsed = urlparse(broker_url)

        self._host = parsed.hostname
        self._port = parsed.port or 443
        self._path = parsed.path or "/"

        self._client = mqtt.Client(
            clean_session=True,
            transport="websockets",
        )
        if parsed.scheme == "wss":
            self._client.tls_set_context(ssl.create_default_context())

        self._client.on_connect = self._on_connect
        self._client.on_message = self._on_message

        self._connected_event = threading.Event()
        self._external_callbacks: List[
            Callable[[mqtt.Client, Any, mqtt.MQTTMessage], None]
        ] = []

    def connect(self) -> None:
        """Open the broker connection and start the background loop."""
        print(f"MQTT: Connecting to {self._host}:{self._port} over {'wss' if self._port == 443 else 'ws'}{self._path}")
        if self._path:
            self._client.ws_set_options(path=self._path)

        self._client.connect(self._host, self._port, keepalive=60)
        self._client.loop_start()

        if not self._connected_event.wait(timeout=5):
            print("MQTT: No CONNACK received within 5 s – check broker reachability")

    def disconnect(self) -> None:
        """Gracefully stop the network loop and disconnect."""
        self._client.loop_stop()
        self._client.disconnect()

    def subscribe(self, topic: str, qos: int = 1) -> None:
        """Subscribe to a topic."""
        self._client.subscribe((topic, qos))
        print(f"MQTT: Subscribed to {topic} (qos={qos})")

    def publish(
        self,
        topic: str,
        payload: str,
        qos: int = 1,
        retain: bool = False,
    ) -> None:
        """Publish a payload to *topic*."""
        self._client.publish(topic, payload, qos=qos, retain=retain)

    def register_callback(
        self, callback: Callable[[mqtt.Client, Any, mqtt.MQTTMessage], None]
    ) -> None:
        """Register a function to receive *all* incoming MQTT messages."""
        self._external_callbacks.append(callback)

    def _on_connect(self, client, userdata, flags, rc):
        print(f"MQTT: connection established")
        self._connected_event.set()

    def _on_message(self, client, userdata, msg):
        for cb in self._external_callbacks:
            try:
                cb(client, userdata, msg)
            except Exception as e:
                print(f"External MQTT callback failed: {e}")
