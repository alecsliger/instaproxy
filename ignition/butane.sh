#!/bin/sh

## Simple script to convert a file named 'butane.yml' into an Ignition file via Docker, 
## then converts for use in ARM template

# Run file through official docker instance
sudo cat butane.yml | sudo docker run --rm -i quay.io/coreos/butane:latest > ignition.json

## Convert to base64 and print to file (If you're lazy enough, I'm sure you could get this to write straight to the parameter file)
base64 -w0 ignition.json > output.txt

# Cleanup (Optional)
# rm ignition.json