import RPi.GPIO as GPIO

"""Controls a relay using GPIO pins on a Raspberry Pi."""
class RelayController:
    def __init__(self, relay_pin: int = 17):
        self.relay_pin = relay_pin
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.relay_pin, GPIO.OUT)
        # Ensure relay is off initially
        GPIO.output(self.relay_pin, GPIO.LOW)


    def toggle_relay(self, on: bool):
        """Turns the relay on or off."""
        if on:
            # If the relay is on, disable it
            GPIO.output(self.relay_pin, GPIO.HIGH)
            print("Relay ON GPIO pin" . format(self.relay_pin))
        else:
            # If the relay is off, enable it
            GPIO.output(self.relay_pin, GPIO.LOW)  # Deactivate SSR
            self.cleanup()
            print("Relay OFF GPIO pin" . format(self.relay_pin))

    def cleanup(self):
        GPIO.cleanup()