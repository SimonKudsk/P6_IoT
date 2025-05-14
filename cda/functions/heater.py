import time
from devices.relay.relay_controller import RelayController
from devices.ds18b20.ds18b20_reader import DS18B20Reader, DS18B20Error
from mqtt.mqtt_publisher import mqtt_publisher

class Heater:
    def __init__(self, target_temperature=100, kettle_relay_pin: int = 17, publisher: mqtt_publisher = None, stop_event=None):
        """
        Initializes the heater.
        :param target_temperature: The target temperature in Celsius.
        :param kettle_relay_pin: The GPIO pin for the kettle relay.
        :param publisher: An instance of mqtt_publisher for publishing temperature progress.
        """
        self.publisher = publisher
        self._stop_event = stop_event
        self.target_temperature = target_temperature
        self.relay_controller = RelayController(kettle_relay_pin)
        self.temp_sensor = DS18B20Reader()
        self.is_heating = False

    def run(self) -> float | None:
        # Start the heater
        print("START HEATER")
        self.relay_controller.toggle_relay(True)
        self.is_heating = True

        try:
            while self.is_heating:
                # Check for stop signal
                if self._stop_event and self._stop_event.is_set():
                    print("Batch stopped by user.")
                    self.relay_controller.toggle_relay(False)
                    return None

                current_temp = self.temp_sensor.read_temp_c()
                print(f"Current temperature: {current_temp:.2f} °C")
                self.publisher.publish_temp_progress(current_temp)

                if current_temp >= self.target_temperature:
                    print("Target temperature reached. Stopping heater.")
                    self.relay_controller.toggle_relay(False)
                    self.is_heating = False
                else:
                    print("Heating...")
                    time.sleep(0.1)  # check temperature every 0.1 seconds

            return self.temp_sensor.read_temp_c()
        except DS18B20Error as exc:
            print(f"Error reading temperature: {exc}")
            self.relay_controller.toggle_relay(False)
            self.is_heating = False
            return None
