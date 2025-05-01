from __future__ import annotations

import glob
import os

BASE_DIR = "/sys/bus/w1/devices"

class DS18B20Error(RuntimeError):
    """Error for lack of data."""

class DS18B20Reader:
    def __init__(self, sensor_id: str | None = None) -> None:
        # Get a list of sensors
        sensors = self.list_sensors()
        # If no sensors are found, raise an error
        if not sensors:
            raise DS18B20Error("No DS18B20 sensors found.")
        # If no sensor ID is provided, use the first one found
        self.sensor_id = sensor_id or sensors[0]
        # If the sensor ID does not start with "28-", prepend it
        if not self.sensor_id.startswith("28-"):
            self.sensor_id = f"28-{self.sensor_id}"
        # Construct the path to the sensor's device file
        self.device_file = os.path.join(BASE_DIR, self.sensor_id, "w1_slave")

    # Function for listing available sensors
    @staticmethod
    def list_sensors():
        # Return a list of detected sensors
        return [os.path.basename(p) for p in glob.glob(os.path.join(BASE_DIR, "28-*"))]

    # Function for reading temperature
    def read_temp_c(self) -> float:
        try:
            # Open the 1-Wire sensor device file as ASCII text
            with open(self.device_file, encoding="ascii") as fh:
                # Read the file, trim whitespace, and split into two lines
                crc_line, data_line = fh.read().strip().splitlines()

        # Raise an error if the file is missing (e.g., sensor unplugged)
        except FileNotFoundError as exc:
            raise DS18B20Error("Sensor disconnected.") from exc

        # Check the CRC line for the “YES” flag indicating valid data
        if not crc_line.endswith("YES"):
            # Abort if the CRC check fails
            raise DS18B20Error("CRC check failed.")

        # Split on “t=” and grab the temperature substring
        _, _, temp_str = data_line.partition("t=")
        # Ensure a temperature value was actually extracted
        if not temp_str:
            raise DS18B20Error("Temperature value not found in device data.")
        # Convert thousandths of a degree to °C and return the value
        return float(temp_str) / 1000.0