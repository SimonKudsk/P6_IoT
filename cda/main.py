from devices.mag6000.mag6000_connector import Mag6000Connector
from devices.relay.relay_controller import RelayController
from functions.flow_monitor import FlowMonitor
from functions.heater import Heater
import signal

def _shutdown_handler(signum, frame):
    """Monitor keyboard interrupts and shutdown signals."""
    raise KeyboardInterrupt

def main():
    # Input data
    liters_to_add = 0.1
    target_temp = 55

    # GPIO pins
    kettle_relay_pin = 17
    pump_relay_pin = 18

    # Register SIGTERM, to cancel execution on termination
    signal.signal(signal.SIGTERM, _shutdown_handler)

    try:
        # Initialize the Mag6000 connector using a context manager to ensure it is discarded when not in use
        # This prevents mounting errors
        with Mag6000Connector() as connector:
            # Initialize the monitor
            monitor = FlowMonitor(
                target_liters=liters_to_add,
                connector=connector,
                pump_relay_pin=pump_relay_pin
            )
            # Start the flow monitor
            result = monitor.run()

            if result:
                print("Container filled successfully.")
            else:
                print("Process terminated due to flow interruption.")

        # Initialize the heater
        heater = Heater(
            target_temperature=target_temp,
            kettle_relay_pin=kettle_relay_pin
        )
        # Start the heater
        heater.run()

    except KeyboardInterrupt:
        print("Operation interrupted by user. Turning off.")

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