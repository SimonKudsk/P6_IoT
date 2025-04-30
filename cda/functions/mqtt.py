import paho.mqtt.client as mqtt
import json
import time
import random

# MQTT broker indstillinger
MQTT_BROKER = "localhost"           # name from docker-compose.yml of influx service + protocol
MQTT_PORT = 1883                    # port
MQTT_TOPIC = "iot/temperature"      # Topic to publish (part of payload), important for influxdb

client = mqtt.Client()

# Tilslut til broker
client.connect(MQTT_BROKER, MQTT_PORT, 60)

# Send data løbende
try:
    while True:
        payload = {
            "temperature": round(random.uniform(10.0, 40.0), 2),
            "humidity": round(random.uniform(40.0, 100.0), 1),
            "device": "sensor_pi"
        }

        client.publish(MQTT_TOPIC, json.dumps(payload))
        print(f"Published: {payload}")
        time.sleep(5)

except KeyboardInterrupt:
    print("Afslutter...")
    client.disconnect()