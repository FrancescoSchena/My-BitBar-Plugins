#!/bin/bash

# Requires blueutil
# https://github.com/toy/blueutil

# to use a txt file for settings change to 0
TXT=1

# Change this with the exact name of your BT device
DEVICE="Surface di Francesco"

CONNECTED=$(/usr/local/bin/blueutil --is-connected "$DEVICE")
# If the device is connected
if [ "$CONNECTED" = "1" ]; then
    echo -n 🎧
# If it is not
elif [ "$CONNECTED" = "0" ]; then
    echo -n 🔈
# Fallback in case of errors
else
    echo -n "ERROR IN DEVICE CONFIGURATION"
fi
