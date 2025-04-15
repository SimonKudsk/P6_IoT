import RPi.GPIO as GPIO

class PumpController:
    def __init__(self, relay_pin=17):
        self.relay_pin = relay_pin
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.relay_pin, GPIO.OUT)
        # Ensure relay is off initially
        GPIO.output(self.relay_pin, GPIO.LOW)

    def toggle_pump(self, on: bool):
        if on:
            GPIO.output(self.relay_pin, GPIO.HIGH)  # Activate SSR
            print("Pump ON")
        else:
            GPIO.output(self.relay_pin, GPIO.LOW)  # Deactivate SSR
            self.cleanup()
            print("Pump OFF")

    def cleanup(self):
        GPIO.cleanup()