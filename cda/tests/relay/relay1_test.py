import unittest
import RPi.GPIO as GPIO
import time
import os
from dotenv import load_dotenv

class TestRelayControl(unittest.TestCase):
    load_dotenv()
    relay_pin = int(os.getenv("PUMP_RELAY_PIN"))
    print("Relay pin:", relay_pin)

    def setUp(self):
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.relay_pin, GPIO.OUT)

    def tearDown(self):
        GPIO.cleanup()

    def test_relay_sequence(self):
        try:
            # SSR off
            GPIO.output(self.relay_pin, GPIO.LOW)
            time.sleep(1)

            # SSR on
            GPIO.output(self.relay_pin, GPIO.HIGH)
            print("SSR activated!")
            time.sleep(2)

            # SSR off again
            GPIO.output(self.relay_pin, GPIO.LOW)
            print("SSR deactivated!")
            time.sleep(1)

            # If no exception happened, pass
            self.assertTrue(True)

        except Exception as e:
            self.fail(f"Relay test failed with exception: {e}")


if __name__ == "__main__":
    unittest.main()