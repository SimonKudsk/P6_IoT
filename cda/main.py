from devices.mag6000.mag6000_connector import Mag6000Connector
from devices.relay.relay_controller import RelayController
from functions.flow_monitor import FlowMonitor
from functions.heater import Heater
import signal
from mqtt.mqtt_connector import mqtt_connector
from mqtt.mqtt_watcher import mqtt_watcher
from mqtt.mqtt_publisher import mqtt_publisher

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
    mqtt.connect()

    # Set up watcher → listens for new requests
    watcher = mqtt_watcher(mqtt)

    # Implementer at den skal melde om sensorer er tilsluttet eller ej
    # den skal sende temperatur, liter påfyldt og flowrate i liter/minut undervejs

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
                    )
                    final_liters = monitor.run()

                if final_liters is not None:
                    publisher.publish_flow_final(final_liters)
                else:
                    publisher.publish_error("interrupted")

                # ------------------ Heating phase -----------------
                heater = Heater(
                    target_temperature=target_temp,
                    kettle_relay_pin=kettle_relay_pin,
                    publisher=publisher,
                )
                final_temp = heater.run()

                if final_temp is not None:
                    publisher.publish_temp_final(final_temp)
                else:
                    publisher.publish_error("interrupted")


            except Exception as exc:
                # Capture *any* error from filling/heating
                publisher.publish_error(str(exc))

    except KeyboardInterrupt:
        print("Operation interrupted by user. Shutting down.")

    finally:
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