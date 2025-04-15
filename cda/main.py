from devices.mag6000.mag6000_connector import Mag6000Connector
from functions.flow_monitor import FlowMonitor

def main():
    liters_to_add = 1

    # Initialize the Mag6000 connector using a context manager to ensure it is discarded when not in use
    # This prevents mounting errors
    with Mag6000Connector() as connector:
        # Create a FlowMonitor with the target liters
        monitor = FlowMonitor(target_liters=liters_to_add, connector=connector)
        result = monitor.run()

        if result:
            print("Process finished successfully.")
        else:
            print("Process terminated due to flow interruption.")

if __name__ == "__main__":
    main()