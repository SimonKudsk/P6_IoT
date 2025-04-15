import time

from devices.mag6000.mag6000_connector import Mag6000Connector
from functions.flow_monitor import FlowMonitor
from functions.heater import Heater

def main():
    liters_to_add = 0.45
    target_temp = 100

    kettle_relay_pin=17
    pump_relay_pin=18

    # Initialize the Mag6000 connector using a context manager to ensure it is discarded when not in use
    # This prevents mounting errors
    with Mag6000Connector() as connector:
        # Create a FlowMonitor with the target liters
        monitor = FlowMonitor(target_liters=liters_to_add, connector=connector, pump_relay_pin=pump_relay_pin)
        result = monitor.run()

        if result:
            print("Container filled successfully.")
        else:
            print("Process terminated due to flow interruption.")

    heater = Heater(target_temperature=target_temp, kettle_relay_pin=kettle_relay_pin)
    heater.run()

if __name__ == "__main__":
    main()