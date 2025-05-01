import struct
import minimalmodbus

class Mag6000Reader:
    def __init__(self, connector):
        # Initializes the reader with an instance of Mag6000Connector.
        self.connector = connector

    def read_flow_rate(self) -> float:
        # Reads the flow rate from register 3002 using function code 3
        # Returns the flow rate in liters per hour
        try:
            # Read a float value (assumed to be in m^3/s) from register 3002
            flow_value = self.connector.instrument.read_float(3002, byteorder=minimalmodbus.BYTEORDER_BIG)
        except Exception as e:
            print("Error reading flow rate:", e)
            return 0.0

        # Convert from m^3/s to liters per hour (1 m^3/s = 3600000 L/h)
        flow_rate_lph = flow_value * 3600000
        return flow_rate_lph

    def read_totalizer(self) -> float:
        """
        Reads the totalizer value from register 3014 using function code 3.
        Returns the cumulative volume (in liters) as a float.
        The raw value is assumed to represent a milliliter count normalized as a double.
        """
        try:
            # Read 4 registers (8 bytes) starting at address 3014
            registers = self.connector.instrument.read_registers(3014, 4)
        except Exception as e:
            print("Error reading totalizer registers:", e)
            return 0.0

        try:
            # Pack the 4 registers (each 16 bits) into 8 bytes in big-endian order
            raw_bytes = struct.pack('>HHHH', registers[0], registers[1], registers[2], registers[3])
            # Unpack the bytes as a 64-bit double in big-endian format
            totalizer_ml = struct.unpack('>d', raw_bytes)[0]
            # Adjusted conversion factor per documentation calibration
            totalizer_liters = totalizer_ml
            return totalizer_liters
        except Exception as e:
            print("Error unpacking totalizer:", e)
            return 0.0