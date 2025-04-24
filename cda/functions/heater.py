import time
from devices.relay.relay_controller import RelayController
from devices.ds18b20.ds18b20_reader import DS18B20Reader, DS18B20Error

class Heater:
    def __init__(self, target_temperature=100, kettle_relay_pin: int = 17):
        """
        Initializes the heater.
        :param target_temperature: The target temperature in Celsius.
        :param kettle_relay_pin: The GPIO pin for the kettle relay.
        """
        self.target_temperature = target_temperature
        self.relay_controller = RelayController(kettle_relay_pin)
        self.temp_sensor = DS18B20Reader()
        self.is_heating = False

    def run(self) -> bool:
        # Start the heater
        print("START HEATER")
        self.relay_controller.toggle_relay(True)
        self.is_heating = True

        try:
            while self.is_heating:
                current_temp = self.temp_sensor.read_temp_c()
                print(f"Current temperature: {current_temp:.2f} °C")

                if current_temp >= self.target_temperature:
                    print("Target temperature reached. Stopping heater.")
                    self.relay_controller.toggle_relay(False)
                    self.is_heating = False
                else:
                    print("Heating...")
                    time.sleep(0.1)  # check temperature every 0.1 seconds

            return True
        except DS18B20Error as exc:
            print(f"Error reading temperature: {exc}")
            self.relay_controller.toggle_relay(False)
            self.is_heating = False
            return False

