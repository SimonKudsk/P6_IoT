import time
from devices.mag6000.mag6000_reader import Mag6000Reader
from devices.relay.relay_controller import RelayController
from mqtt.mqtt_publisher import mqtt_publisher

class FlowMonitor:
    def __init__(self, target_liters: float, connector, pump_relay_pin: int = 18, publisher: mqtt_publisher = None):
        """
        Initializes the flow monitor.

        :param target_liters: The target volume (in liters) to be added.
        :param connector: An instance of Mag6000Connector.
        :param pump_relay_pin: The GPIO pin for the pump relay.
        :param publisher: An instance of mqtt_publisher for publishing temperature progress.
        """
        self.publisher = publisher
        self.target_liters = target_liters
        self.connector = connector
        self.flow_threshold = 10  # minimum flow rate in L/h considered as "flowing"
        self.reader = Mag6000Reader(connector) # Instantiate the reader that will be used for reading values.
        self.pump_controller = RelayController(pump_relay_pin) # Initialize the relay controller for the pump

    def run(self) -> float | None:
        """
        Monitors the flow until the target liter count is reached.
        Returns True if the target is reached, or False if there is no flow
        for more than 10 seconds.
        """

        # Get the baseline and target totalizer values via the reader
        started = False
        baseline_total = self.reader.read_totalizer()
        volume_moved = 0.0
        prev_timestamp = time.time()
        recorded_flow_rates = []

        # Start the pump
        print("START PUMP")
        self.pump_controller.toggle_relay(True)

        last_flow_time = time.time()
        while not started:
            current_total = self.reader.read_totalizer()
            if current_total > baseline_total:
                started = True
                last_flow_time = time.time()
                print("Flow has started")
            elif time.time() - last_flow_time > 10:   # same 10-s rule you use later
                print("ERROR: No flow detected for 10 seconds after starting the pump. Aborting execution.")
                self.pump_controller.toggle_relay(False)
                return False
            time.sleep(0.1)

        # Main monitoring loop
        while started:
            current_timestamp = time.time()
            elapsed_time = current_timestamp - prev_timestamp
            prev_timestamp = current_timestamp

            flow_rate = self.reader.read_flow_rate()

            # Append current flow rate to the array and average it
            recorded_flow_rates.append(flow_rate)
            average_flow_rate = sum(recorded_flow_rates) / len(recorded_flow_rates)

            # Update the total volume moved using the current flow rate (convert L/h to L/s)
            volume_moved += (average_flow_rate / 3600.0) * elapsed_time

            # Read the current totalizer value relative to baseline
            current_total = self.reader.read_totalizer() - baseline_total

            # The sensor totalizer updates in jumps, which may lag behind actual flow.
            # Meanwhile, the instantaneous flow rate provides continuous data that is integrated over time.
            # By taking the maximum of the totalizer reading (adjusted to baseline) and the integrated flow,
            # we have a better chance of getting the actual newest volume.
            highest_volume = max(current_total, volume_moved)

            print(f"Progress: {highest_volume:.2f} out of {self.target_liters:.2f} liters passed")
            self.publisher.publish_flow_progress(highest_volume)

            if flow_rate > self.flow_threshold:
                print(f"Flow going at {flow_rate:.2f} l/h")
                last_flow_time = current_timestamp  # update the last time flow was detected
            else:
                print("ERROR SIGNAL: No flow detected. Waiting 10 seconds before aborting.")
                if last_flow_time is not None and (current_timestamp - last_flow_time > 10):
                    print("ERROR: No flow detected for more than 10 seconds. Aborting.")
                    self.pump_controller.toggle_relay(False)
                    return None

            if highest_volume >= self.target_liters - 0.05:
                self.pump_controller.toggle_relay(False)
                print("FINISHED: Target reached.")
                return highest_volume

            time.sleep(0.25)

        # Return false if execution fails
        return None