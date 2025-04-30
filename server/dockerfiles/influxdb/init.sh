#!/bin/bash

# Indlæs .env-variabler
set -a
source .env
set +a

# Wait until InfluxDB is ready
sleep 5

# Opret ekstra bucket til nodered
influx bucket create \
  --name nodered \
  --org "$INFLUXDB_ORG" \
  --token "$INFLUXDB_ADMIN_TOKEN"  \
  --host "http://${INFLUXDB_HOSTNAME}:${INFLUXDB_PORT}"

echo "nodered testBucket created!"


# Opret python hardware bucket til drift
influx bucket create \
  --name IoT-Bucket \
  --org "$INFLUXDB_ORG" \
  --token "$INFLUXDB_ADMIN_TOKEN"  \
  --host "http://${INFLUXDB_HOSTNAME}:${INFLUXDB_PORT}"

echo "python hardware testBucket created!"



# Run the following command once to execute the file at docker build: chmod +x dockerfiles/influxdb/init.sh