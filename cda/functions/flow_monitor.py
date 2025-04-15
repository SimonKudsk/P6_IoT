import time
from devices.relay.pump_controller import PumpController

class FlowMonitor:
    def __init__(self, target_liters: float, connector):
        """
        Initializes the flow monitor.

        :param target_liters: The target volume (in liters) to be added.
        :param connector: An instance of Mag6000Connector.
        """
        self.target_liters = target_liters
        self.connector = connector
        self.flow_threshold = 10  # minimum flow rate in L/h considered as "flowing"
        from devices.mag6000.mag6000_reader import Mag6000Reader
        self.reader = Mag6000Reader(connector) # Instantiate the reader that will be used for reading values.

    def run(self) -> bool:
        """
        Monitors the flow until the target liter count is reached.
        Returns True if the target is reached, or False if there is no flow
        for more than 10 seconds.
        """

        # Get the baseline and target totalizer values via the reader
        started = False
        baseline_total = self.reader.read_totalizer()
        target_total = baseline_total + self.target_liters
        last_flow_time = None
        pump_controller = PumpController()

        # Start the pump
        print("START PUMP")
        pump_controller.toggle_pump(True)

        # Wait for flow to start
        while not started:
            current_total = self.reader.read_totalizer()
            if current_total > baseline_total:
                started = True
                last_flow_time = time.time()
                print("Flow has started")
            time.sleep(0.1)

        # Main monitoring loop
        while started:
            current_total = self.reader.read_totalizer()
            flow_rate = self.reader.read_flow_rate()
            current_time = time.time()

            progress = current_total - baseline_total
            print(f"Progress: {progress:.2f} out of {self.target_liters:.2f} liters passed")

            if flow_rate > self.flow_threshold:
                print(f"Flow going at {flow_rate:.2f} l/h")
                last_flow_time = current_time  # update the last time flow was detected
            else:
                print("ERROR SIGNAL: No flow detected. Waiting 10 seconds before aborting.")
                if last_flow_time is not None and (current_time - last_flow_time > 10):
                    print("ERROR: No flow detected for more than 10 seconds. Aborting.")
                    return False

            if current_total >= target_total:
                pump_controller.toggle_pump(False)
                print("FINISHED: Target reached.")
                return True

            time.sleep(0.25)