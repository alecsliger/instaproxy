#!/bin/sh
## A script to convert a Butane file named 'butane.yml' into an Ignition file via Docker, and then into base64

# This will run the file through official coreos butane container for conversion
sudo cat butane.yml | sudo docker run --rm -i quay.io/coreos/butane:latest > ignition.json

## Convert to base64 and print to 'output.txt'
base64 -w0 ignition.json > output.txt

# Cleanup unused ignition file
rm ignition.json