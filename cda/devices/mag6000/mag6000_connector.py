import time
import os
import minimalmodbus
import serial

class Mag6000Connector:
    def __init__(self):
        # Initialize the connector with a port and slave address.
        self.port = "/dev/ttyUSB0"
        self.slave_address = 1
        self.instrument = None
        self._initialize_instrument()

    def close(self):
        # Close the serial connection if it is ope
        if self.instrument is not None:
            try:
                self.instrument.serial.close()
            except Exception as e:
                print("Error closing instrument:", e)
            self.instrument = None

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()

    def _initialize_instrument(self):
        # Wait until the device file is accessible
        while not os.path.exists(self.port):
            print(f"Waiting for {self.port} to be accessible...")
            time.sleep(1)

        # Set up the serial connection with the correct settings
        minimalmodbus.MODE_RTU = 'rtu'
        while True:
            try:
                # Settings as per the Siemens instructions
                self.instrument = minimalmodbus.Instrument(self.port, self.slave_address)
                self.instrument.address = self.slave_address
                self.instrument.serial.baudrate = 19200
                self.instrument.serial.interframe_space = 3.5
                self.instrument.serial.timeout = 2  # seconds
                self.instrument.serial.parity = serial.PARITY_EVEN
                self.instrument.serial.stopbits = 1
                self.instrument.serial.bytesize = 8
                return
            except OSError as e:
                print("Error initializing instrument:", e)
                print("Retrying after 2 seconds...")
                time.sleep(2)