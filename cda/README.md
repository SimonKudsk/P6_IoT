# CDA Code for Raspberry Pi
This Python project contains the CDA device code for our project.

Please note that this setup is only meant to run on Raspberry Pi devices.

## Hardware
This project depends on specific sensors to function.

### DS18B20
The DS18B20 is a digital temperature sensor. It is connected to the Raspberry Pi via GPIO pins. The sensor uses the 1-Wire protocol to communicate with the Raspberry Pi.

For this to function, one wire has to be enabled in the Raspberry Pi settings.

### Solid state relay
To control the heater and pump, we use solid state relays. No specific model have to be used for this, but ensure that the relay can handle the current of the heater and pump.

They should be connected to the Raspberry Pi via GPIO pins. These pins are set in the .env file, which will be described later.

### Flow gauge
To read the flow of liquid, we used 3 Siemens devices in conjunction:
- SITRANS FM MAG 6000 – an electromagnetic flow transmitter, which processes the sensor signal and provides outputs/communications.
- SITRANS FM MAG 1100 F – an electromagnetic flow sensor, designed for hygienic applications.
- SITRANS F Modbus RTU/RS-485 module - a Modbus module installed within the MAG 6000, for external communications.

To interface with this, we connected a 2-wire modbus TS485 USB adapter to the Modbus module, which is connected to the Raspberry Pi via USB. The USB port is set in the .env file, which will be described later.

## Configuration of .env
The project uses an .env file for configuration. An example file is in the project directory, called .env_example. This file should be copied to .env and edited to fit your needs.

### MQTT Domain
The project uses MQTT to communicate with the server. The domain should be set to the domain of the server. Please note, this must be passed through HTTPS port 443, and use wss for the websocket connection. As port and protocol is hardcoded for compatibility, this should not be in the .env file.

The variable is:
- MQTT_DOMAIN

### USB Port for the flow gauge modbus device
The project uses a USB port to communicate with the flow gauge. The port should be set to the port of the USB device. This can be found by executing command `ls /dev/ttyUSB*` in the terminal. The variable is:
- FLOW_GAUGE_PORT

### Relay GPIO pins
The project uses GPIO pins to control the relays. The pins should be set to the GPIO pins of the relays. The variables are:
- HEATER_RELAY_PIN
- RELAY_HEATER_PIN

## Running the project
To run the project, we recommend using the provided Docker Compose file, located in ../cda_docker. This will automatically install required packages, and run the project.
