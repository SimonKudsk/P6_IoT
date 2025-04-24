from devices.mag6000.mag6000_connector import Mag6000Connector
from functions.flow_monitor import FlowMonitor
from functions.heater import Heater
import signal

def _shutdown_handler(signum, frame):
    """Monitor keyboard interrupts and shutdown signals."""
    raise KeyboardInterrupt

def main():
    liters_to_add = 0.1
    target_temp = 55

    # Register SIGTERM, to cancel execution on termination
    signal.signal(signal.SIGTERM, _shutdown_handler)

    # Placeholders
    monitor = None
    heater = None

    kettle_relay_pin=17
    pump_relay_pin=18

    try:
        # Initialize the Mag6000 connector using a context manager to ensure it is discarded when not in use
        # This prevents mounting errors
        with Mag6000Connector() as connector:
            # Create a FlowMonitor with the target liters
            monitor = FlowMonitor(
                target_liters=liters_to_add,
                connector=connector,
                pump_relay_pin=pump_relay_pin
            )
            result = monitor.run()

            if result:
                print("Container filled successfully.")
            else:
                print("Process terminated due to flow interruption.")

        heater = Heater(
            target_temperature=target_temp,
            kettle_relay_pin=kettle_relay_pin
        )
        heater.run()

    except KeyboardInterrupt:
        print("Operation interrupted by user. Turning off.")

    finally:
        # Ensure relays are always off before exit
        if monitor is FlowMonitor:
            monitor.pump_controller.toggle_relay(False)
            print("Turned off pump.")
        if heater is not None:
            heater.relay_controller.toggle_relay(False)
            print("Turned off heater.")
        print("Finished turning off.")

if __name__ == "__main__":
    main()