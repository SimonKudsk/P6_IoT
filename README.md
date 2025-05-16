# P6 IoT project
This project was made as a part of our bachelor project at Aalborg University, for the Information Technologies program.

The project is for controlling a miniature pasteurization facility, made with IoT in mind. This repository contains 3 seperate parts.

## CDA
The CDA code is the code that runs on the Raspberry Pi written in Python. It controls the hardware, and communicates with the server via MQTT.

This consists of two folders:
- `cda`: The code that runs on the Raspberry Pi. This is the main code. Read the [readme](cda/README.md) in this folder for more information.
- `cda_docker`: The Docker setup for the Raspberry Pi. This is used to run the code in the `cda` folder. Read the [readme](cda_docker/README.md) in this folder for more information.

## Controller app
The controller app is a multi-platform Flutter app, that is used to control the CDA device. It communicates with the server via MQTT, sending orders and receiving updates.

You can read more, including setup instructions, in the [readme](controller_app/README.md) in the `controller_app` folder.

## Server
This is the server-side Docker Compose setup for our project. It uses the following services:
- `nginx`: The reverse proxy. This is used to route the traffic to the correct services.
- `cloudflared`: The tunnel to the public internet. This is used to connect the server to the public internet via Cloudflare tunnels.
- `mosquitto`: The MQTT broker. This is used to communicate with the CDA device and the controller app.
- `telegraf`: The data collector. This is used to collect the data from the MQTT broker and send it to the InfluxDB database.
- `influxdb`: The time-series database. This is used to store the data from the CDA device.
- `grafana`: The dashboard. This is used to visualize the data from the InfluxDB database.
- `nodered`: The flow-based programming tool. This is used to create the flows for the CDA device. It is also used to create the dashboard for the CDA device.

More can be read, including setup, in the [readme](server/README.md) in the `server` folder.