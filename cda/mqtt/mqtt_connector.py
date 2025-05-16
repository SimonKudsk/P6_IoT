from __future__ import annotations
import threading
from typing import Callable, List, Any
import paho.mqtt.client as mqtt
import ssl

class mqtt_connector:

    def __init__(
        self,
        broker_url: str,
    ) -> None:
        print(f"MQTT: Initialising connector for {broker_url}")

        # Connection parameters for MQTT broker
        self._host = broker_url
        self._port = 443
        self._path = "/"

        # Track subscriptions to re-subscribe after reconnects
        self._subscriptions: list[tuple[str, int]] = []

        # Instantiate MQTT client with provided options
        self._client = mqtt.Client(
            clean_session=True,  # Start with a clean session (no persistent session)
            transport="websockets",  # Use WebSockets transport for MQTT
        )
        # Use TLS for secure connection
        self._client.tls_set_context(ssl.create_default_context())

        # Assign handlers for MQTT events
        self._client.on_connect = self._on_connect
        self._client.on_message = self._on_message

        # Event to signal when connection is established
        self._connected_event = threading.Event()
        self._external_callbacks: List[  # List of callbacks for incoming messages
            Callable[[mqtt.Client, Any, mqtt.MQTTMessage], None]
        ] = []
        # List of callbacks to run on connection
        self._connect_callbacks: list[Callable[[], None]] = []

    def connect(self) -> None:
        """Open the broker connection and start the background loop."""
        print(f"MQTT: Connecting to {self._host}:{self._port} over {'wss' if self._port == 443 else 'ws'}{self._path}")

        # If a WebSocket path is specified
        if self._path:
            # Set WebSocket options on client - this is required for the connection
            self._client.ws_set_options(path=self._path)

        # Initiate connection to broker with keepalive
        self._client.connect(self._host, self._port, keepalive=10)
        # Start network loop in background thread
        self._client.loop_start()

        # Wait for on_connect event with timeout
        if not self._connected_event.wait(timeout=5):
            # Warn if no connection ack received, due to the broker being unreachable
            print("MQTT: No CONNACK received within 5 s – check broker reachability")

    def disconnect(self) -> None:
        """Gracefully stop the network loop and disconnect."""

        # Stop the network loop and disconnect from the broker
        self._client.loop_stop()
        self._client.disconnect()

    def subscribe(self, topic: str, qos: int = 1) -> None:
        """Subscribe to a topic."""
        # Subscribe to topic with specified QoS
        self._client.subscribe((topic, qos))
        # Store subscription for future resubscription
        self._subscriptions.append((topic, qos))
        print(f"MQTT: Subscribed to {topic}")

    def publish(
        self,
        topic: str, # Topic to publish to
        payload: str, # Payload message to send
        qos: int = 1, # MQTT QoS level: 0=at most once, 1=at least once, 2=exactly once
        retain: bool = True, # Whether the message should be retained by the broker
    ) -> None:
        """Publish a payload to *topic*."""
        self._client.publish(topic, payload, qos=qos, retain=retain)

    def register_callback(
        self, callback: Callable[[mqtt.Client, Any, mqtt.MQTTMessage], None]
    ) -> None:
        """Register a function to receive *all* incoming MQTT messages."""
        self._external_callbacks.append(callback)

    def register_on_connect(self, callback: Callable[[], None]) -> None:
        """Register a function to call when MQTT connection is established."""
        self._connect_callbacks.append(callback)

    def _on_connect(self, client, userdata, flags, rc):
        """Handles when the client connects to the broker."""
        print(f"MQTT: connection established")
        # Signal that connection event occurred
        self._connected_event.set()
        # Re-subscribe to any topics after reconnect
        for topic, qos in self._subscriptions:
            self._client.subscribe((topic, qos))
            print(f"MQTT: Resubscribed to {topic}")

        # Trigger any on-connect callbacks, as defined in register_on_connect
        for cb in self._connect_callbacks:
            try:
                cb()
            except Exception as e:
                print(f"On-connect callback failed: {e}")

    def _on_message(self, client, userdata, msg):
        """Handles when a message is received on a subscribed topic."""
        # Check with external callbacks
        for cb in self._external_callbacks:
            try:
                cb(client, userdata, msg)
            except Exception as e:
                print(f"External MQTT callback failed: {e}")
