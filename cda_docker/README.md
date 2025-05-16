# CDA Docker setup
This docker setup is made to run on the CDA devices, with minimal configuration. It executes the code in the ../cda directory.

Please note that this setup is only meant to run on Raspberry Pi devices.

## Setup
Before running the Docker setup, please read the README.md in the ../cda directory. This will explain how to set up the environment variables, for the project to work.

## Running the project
When you are ready, simply run the following command in the cda_docker directory:

```docker compose up -d```

With this, the project will start instantly. It will also restart, after a shutdown or crash of the Pi.