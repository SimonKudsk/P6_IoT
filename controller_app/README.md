# controller_app
This Flutter app is made to control the CDA device. It communicates with the server via MQTT, sending orders and receiving updates to display on the app.

## Environment variables
Before running the project, make sure to configure the environment variables in the `.env` file. An example file is provided as `.env_example`. Copy this file to `.env` and edit it to fit your needs.

Currently, there is only one environment variable.

### MQTT_DOMAIN
The project uses MQTT to communicate with the server. The domain should be set to the domain of the server. Please note, this must be passed through HTTPS port 443, and use wss for the websocket connection. As port and protocol is hardcoded for compatibility, this should not be in the `.env` file.