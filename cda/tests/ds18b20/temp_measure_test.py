import time
import unittest
from devices.ds18b20.ds18b20_reader import DS18B20Reader, DS18B20Error


class TempMeasureTest(unittest.TestCase):

    def setUp(self):
        sensors = DS18B20Reader.list_sensors()
        if not sensors:
            self.skipTest(
                "No DS18B20 sensors detected – skipping hardware tests."
            )
        self.reader = DS18B20Reader(sensors[0])

    def test_temperature_range(self):
        end_time = time.time() + 5.0
        last_read = None

        while time.time() < end_time:
            try:
                last_read = self.reader.read_temp_c()
                print(f"{last_read:6.2f} °C")
            except DS18B20Error as exc:
                self.fail(f"Failed to read sensor: {exc}")

            time.sleep(0.1)

        # Use the final reading for the check
        self.assertIsNotNone(last_read)
        self.assertIsInstance(last_read, float)
        self.assertGreaterEqual(last_read, -10.0)
        self.assertLessEqual(last_read, 125.0)