import json

STATUS_TOPIC_TEMPLATE = "devices/{device_id}/status"

class DeviceStatusPublisher:
    """
    Publishes availability and occupation status for a given device_id.
    """

    def __init__(self, connector, device_id: str):
        self._connector = connector
        self._device_id = device_id
        self._status_topic = STATUS_TOPIC_TEMPLATE.format(device_id=device_id)

    def configure_lwt(self):
        """
        Configure Last Will so that if the client disconnects ungracefully,
        the broker will publish 'offline'.
        """
        self._connector._client.will_set(
            self._status_topic,
            json.dumps({"status": "offline"}),
            qos=1,
            retain=True
        )

    def mark_online(self):
        """Publish 'available' when the device comes online."""
        self._connector.publish(
            self._status_topic,
            json.dumps({"status": "available"}),
            qos=1,
            retain=True
        )

    def mark_offline(self):
        """Publish 'offline' on graceful shutdown."""
        self._connector.publish(
            self._status_topic,
            json.dumps({"status": "offline"}),
            qos=1,
            retain=True
        )

    def mark_occupied(self, lot_number: str):
        """Publish 'occupied' and include the lot_number."""
        self._connector.publish(
            self._status_topic,
            json.dumps({"status": "occupied", "lot_number": lot_number}),
            qos=1,
            retain=True
        )

    def mark_error(self, error_message: str):
        """Publish 'error' with an error message."""
        self._connector.publish(
            self._status_topic,
            json.dumps({"status": "error", "error_message": error_message}),
            qos=1,
            retain=True
        )

    def mark_available(self):
        """Publish 'available' when the device finishes processing."""
        self._connector.publish(
            self._status_topic,
            json.dumps({"status": "available"}),
            qos=1,
            retain=True
        )
