import RPi.GPIO as GPIO

class RelayController:
    def __init__(self, relay_pin: int = 17):
        self.relay_pin = relay_pin
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.relay_pin, GPIO.OUT)
        # Ensure relay is off initially
        GPIO.output(self.relay_pin, GPIO.LOW)

    def toggle_relay(self, on: bool):
        if on:
            GPIO.output(self.relay_pin, GPIO.HIGH)  # Activate SSR
            print("Relay ON GPIO pin" . format(self.relay_pin))
        else:
            GPIO.output(self.relay_pin, GPIO.LOW)  # Deactivate SSR
            self.cleanup()
            print("Relay OFF GPIO pin" . format(self.relay_pin))

    def cleanup(self):
        GPIO.cleanup()