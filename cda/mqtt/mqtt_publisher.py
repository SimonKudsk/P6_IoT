from mqtt.mqtt_connector import mqtt_connector
import json

FLOW_PROGRESS_TOPIC = "sensor/flow_gauge/progress"
TEMP_PROGRESS_TOPIC = "sensor/temp_sensor/progress"
FLOW_FINAL_TOPIC = "sensor/flow_gauge/final"
TEMP_FINAL_TOPIC = "sensor/temp_sensor/final"

class mqtt_publisher:
    """
    Helper that publishes progress and final results including lot_id and line number.
    """

    def __init__(self, connector: mqtt_connector, lot_id: str, line: int) -> None:
        self._connector = connector
        self._lot_id = lot_id
        self._line = line

    def _publish(self, topic: str, data: dict) -> None:
        """
        Send `data` as JSON on *topic* (with the retain flag set).
        All payloads carry `lot_id`, `line`, and `device="pi"` as required by the interface spec.
        """
        data |= {"lot_number": self._lot_id, "line": self._line, "device": "pi"}
        self._connector.publish(topic, json.dumps(data), qos=1, retain=True)

    def publish_flow_progress(self, liters: float) -> None:
        """Send an in‑flight update from the flow gauge."""
        self._publish(FLOW_PROGRESS_TOPIC, {"liters": liters})

    def publish_flow_final(self, liters: float) -> None:
        """Send an in‑flight update from the flow gauge."""
        self._publish(FLOW_FINAL_TOPIC, {"liters": liters})
        print("Publishing final results L" + str(liters))

    def publish_temp_progress(self, temperature: float) -> None:
        """Send an in‑flight update from the temperature sensor."""
        self._publish(TEMP_PROGRESS_TOPIC, {"temperature": temperature})

    def publish_temp_final(self, temperature: float) -> None:
        """Send an in‑flight update from the temperature sensor."""
        self._publish(TEMP_FINAL_TOPIC, {"temperature": temperature})
        print("Publishing final results at °C" + str(temperature))

    def publish_error(self, message: str) -> None:
        """Broadcast an error message on the progress topics."""
        self._publish(FLOW_PROGRESS_TOPIC, {"error": message})
        self._publish(TEMP_PROGRESS_TOPIC, {"error": message})
