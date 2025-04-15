import time
from devices.relay.relay_controller import RelayController

class Heater:
    def __init__(self, target_temperature=100, kettle_relay_pin: int = 17):
        """
        Initializes the heater.
        :param target_temperature: The target temperature in Celsius.
        :param kettle_relay_pin: The GPIO pin for the kettle relay.
        """
        self.target_temperature = target_temperature
        self.relay_controller = RelayController(kettle_relay_pin)
        self.is_heating = False
        
    def run(self) -> bool:
        # Start the heater
        print("START HEATER")
        self.relay_controller.toggle_relay(True)
        self.is_heating = True
        
        # Wait for the target temperature to be reached
        time.sleep(5)
        self.relay_controller.toggle_relay(False)
        return True
        