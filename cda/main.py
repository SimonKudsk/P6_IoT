from devices.mag6000.mag6000_connector import Mag6000Connector
from devices.relay.relay_controller import RelayController
from functions.flow_monitor import FlowMonitor
from functions.heater import Heater
import signal
from functions.serial_num import get_serial
from mqtt.mqtt_connector import mqtt_connector
from mqtt.mqtt_watcher import mqtt_watcher
from mqtt.mqtt_publisher import mqtt_publisher
from mqtt.device_status import DeviceStatusPublisher
import threading
import json

# Get the device ID from the serial number
DEVICE_ID = get_serial()

def deactivate_line(publisher):
    """Stops the current process."""
    publisher.publish_error("interrupted")


def _shutdown_handler(signum, frame):
    """Monitor keyboard interrupts and shutdown signals."""
    raise KeyboardInterrupt


def main():
    # GPIO pins
    kettle_relay_pin = 17
    pump_relay_pin = 18

    # Register SIGTERM, to cancel execution on termination
    signal.signal(signal.SIGTERM, _shutdown_handler)

    # MQTT connection
    mqtt = mqtt_connector()
    status_publisher = DeviceStatusPublisher(mqtt, DEVICE_ID)
    status_publisher.configure_lwt()
    # When connected, instantly mark as online
    mqtt.register_on_connect(status_publisher.mark_online)
    mqtt.connect()

    # Subscribe to stop signals
    STOP_TOPIC = "request/process/stop"
    mqtt.subscribe(STOP_TOPIC, qos=1)

    # Set up watcher → listens for new requests
    watcher = mqtt_watcher(mqtt)

    try:
        while True:
            # ------------------------------------------------------
            # IDLE: wait until we have both litres and temperature
            # ------------------------------------------------------
            order = watcher.wait_for_order()
            liters_to_add = order["liters"]
            target_temp = order["temperature"]
            line = order["line"]
            lot_id = order["lot_number"]
            status_publisher.mark_occupied(lot_id)

            # Set up stop event for this lot
            stop_event = threading.Event()

            def _on_stop_signal(client, userdata, msg):
                try:
                    payload = json.loads(msg.payload.decode())
                    if payload.get("lot_number") == lot_id:
                        print(f"Stop signal received for lot {lot_id}")
                        stop_event.set()
                except json.JSONDecodeError:
                    pass

            # Register stop callback
            mqtt.register_callback(_on_stop_signal)

            publisher = mqtt_publisher(mqtt, lot_id, line)
            print(f"Received request → {liters_to_add} L at {target_temp} °C")

            try:
                # ------------------ Filling phase -----------------
                with Mag6000Connector() as connector:
                    print("[DEBUG] Connected to sensor")
                    monitor = FlowMonitor(
                        target_liters=liters_to_add,
                        connector=connector,
                        pump_relay_pin=pump_relay_pin,
                        publisher=publisher,
                        stop_event=stop_event,
                    )
                    final_liters = monitor.run()

                if final_liters is not None:
                    publisher.publish_flow_final(final_liters)
                else:
                    deactivate_line(publisher)
                    print("Flow interrupted")
                    status_publisher.mark_error("Flow interrupted")
                    continue

                # ------------------ Heating phase -----------------
                heater = Heater(
                    target_temperature=target_temp,
                    kettle_relay_pin=kettle_relay_pin,
                    publisher=publisher,
                    stop_event=stop_event,
                )
                final_temp = heater.run()

                if final_temp is not None:
                    publisher.publish_temp_final(final_temp)
                    status_publisher.mark_available()
                else:
                    deactivate_line(publisher)
                    print("Heater interrupted")
                    status_publisher.mark_error("Heater interrupted")
                    continue


            except Exception as exc:
                # Capture *any* error from filling/heating
                publisher.publish_error(str(exc))
                status_publisher.mark_available()

    except KeyboardInterrupt:
        print("Operation interrupted by user. Shutting down.")

    finally:
        status_publisher.mark_offline()
        # Ensure pump is off
        pump_relay_controller = RelayController(pump_relay_pin)
        pump_relay_controller.toggle_relay(False)
        print("Turned off pump.")

        # Ensure heater is off
        heater_relay_controller = RelayController(kettle_relay_pin)
        heater_relay_controller.toggle_relay(False)
        print("Turned off heater.")

        print("Finished turning off.")


if __name__ == "__main__":
    main()
