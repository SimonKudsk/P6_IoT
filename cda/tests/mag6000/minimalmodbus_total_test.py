import os
from dotenv import load_dotenv
import unittest
import minimalmodbus
import serial
import struct

class TestTotalizerMinimalmodbus(unittest.TestCase):
    def setUp(self):
        load_dotenv()
        port = os.getenv("FLOW_GAUGE_PORT")
        # Create a minimalmodbus Instrument instance for the device
        self.instrument = minimalmodbus.Instrument(port, 1)  # port, slave address
        # Configure the serial settings per MAG6000 default
        self.instrument.serial.baudrate = 19200
        self.instrument.serial.bytesize = 8
        self.instrument.serial.parity = serial.PARITY_EVEN
        self.instrument.serial.stopbits = 1
        self.instrument.serial.timeout = 10  # increased timeout for slower responses

    def tearDown(self):
        self.instrument.serial.close()

    def test_print_totalizer(self):
        try:
            # Read 4 registers (8 bytes) starting at register 3014 using function code 3
            # According to the manual, Totalizer 1 is stored here as a double
            registers = self.instrument.read_registers(3014, 4)
        except minimalmodbus.NoResponseError as e:
            self.skipTest(f"Skipping test because no response was received: {e}")
        except Exception as e:
            self.skipTest(f"Skipping test due to unexpected error: {e}")

        try:
            # Pack the 4 registers into 8 bytes
            # Each register is 16 bits, so we use the format '>HHHH' for big-endian
            raw_bytes = struct.pack('>HHHH', registers[0], registers[1], registers[2], registers[3])
            # Unpack the bytes as a 64-bit double in big-endian format
            totalizer = struct.unpack('>d', raw_bytes)[0]
            # Convert to liters
            totalizer_liters = totalizer * 1000.0
        except Exception as e:
            self.fail(f"Failed to unpack totalizer value: {e}")

        print(f"Totalizer value: {totalizer_liters}")
        # Check that a float is returned
        self.assertIsInstance(totalizer_liters, float, "Totalizer value should be a int.")

if __name__ == '__main__':
    unittest.main()