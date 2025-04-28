#!/bin/bash
# Wait until InfluxDB is ready
sleep 5

# Opret ekstra bucket til test
influx bucket create \
  --name testBucket \
  --org IoT-Org \
  --token SuperSecretToken \
  --host http://localhost:8086

echo "testBucket created!"




# Run the following command once to execute the file at docker build: chmod +x dockerfiles/influxdb/init.sh