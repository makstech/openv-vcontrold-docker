#!/bin/bash

sleep 3

USB_DEVICE="${USB_DEVICE:-/dev/vitocal}"
echo "Device ${USB_DEVICE}"

# Make some stuff accessible
chmod 777 ${USB_DEVICE}
chmod +x /config/mqtt_sub.sh /config/mqtt_publish.sh

# Create the output file
touch result.json

# Start the daemon
vcontrold -x /config/vcontrold.xml -P /var/run/vcontrold.pid

status=$?
pid=$(pidof vcontrold)
if [ $status -ne 0 ]; then
    echo "Failed to start the vcontrold"
fi

if [ $MQTTACTIVE = true ]; then
    echo "vcontrold started with PID $pid"
    echo "MQTT: active"
    echo "Update interval: $INTERVAL sec"
    echo "Reading parameters: $COMMANDS"
    /config/mqtt_sub.sh
    while sleep $INTERVAL; do
        vclient -h 127.0.0.1:3002 -c ${COMMANDS} -J -o result.json
        /config/mqtt_publish.sh
        if [ -e /var/run/vcontrold.pid ]; then
            :
        else
            echo "vcontrold.pid unavailable, exit 0"
            exit 0
        fi
    done
else
    echo "vcontrold started"
    echo "MQTT: inactive (var = $MQTTACTIVE)"
    echo "PID: $pid"
    while sleep 600; do
        if [ -e /var/run/vcontrold.pid ]; then
            :
        else
            echo "vcontrold.pid unavailable, exit 0"
            exit 0
        fi
    done
fi
