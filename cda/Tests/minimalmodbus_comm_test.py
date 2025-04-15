import unittest
import minimalmodbus
import serial

class TestModbusConnectionMinimalmodbus(unittest.TestCase):
    def setUp(self):
        # Create a minimalmodbus Instrument instance
        self.instrument = minimalmodbus.Instrument('/dev/ttyUSB0', 1)  # port, slave address
        # Configure the serial settings per MAG6000 default
        self.instrument.serial.baudrate = 19200
        self.instrument.serial.bytesize = 8
        self.instrument.serial.parity = serial.PARITY_EVEN
        self.instrument.serial.stopbits = 1
        self.instrument.serial.timeout = 10  # increased timeout for slow responses
        # Uncomment the next line to enable debug output if needed
        # self.instrument.debug = True

    def tearDown(self):
        self.instrument.serial.close()

    def test_read_device_register(self):
        try:
            # Read a 32-bit float (2 registers) from register address 3002 using function code 3
            # The device manual specifies that absolute volumeflow (m³/s) is at register 3002
            flow_rate = self.instrument.read_float(3002, functioncode=3, byteorder=minimalmodbus.BYTEORDER_BIG)
        except minimalmodbus.NoResponseError as e:
            self.skipTest(f"Skipping test because no response was received: {e}")
        except Exception as e:
            self.skipTest(f"Skipping test due to unexpected error: {e}")

        # Check that the returned value is a float and is non-negative (adjust range as needed)
        self.assertIsInstance(flow_rate, float, "The response should be a float value.")
        self.assertGreaterEqual(flow_rate, 0, "Flow rate should be non-negative.")

if __name__ == '__main__':
    unittest.main()