#!/bin/bash
# metadata
# <bitbar.title>Surface connected</bitbar.title>

# Requires blueutil and grep
# https://github.com/toy/blueutil

if [ "1" = "0" ]; then
    mkdir headphones
    FILE="/Users/francesco/Documents/BitBar Plugins/headphones/headphones_name.txt"
    PLACEHOLDER="<Insert device name in the txt>"

    if [ -f "$FILE" ]; then
        NAME=$(cat "$FILE")
    else
        echo "$PLACEHOLDER" > "$FILE"
    fi

    if [ "$NAME" != "$PLACEHOLDER" ]; then
        CONNECTED=$(/usr/local/bin/blueutil --is-connected "$NAME")
        if [ "$CONNECTED" = "1" ]; then
            echo -n 🎧
        else
            echo -n 🔈
        fi
    else
        echo -n $NAME
    fi
else
    CONNECTED=$(/usr/local/bin/blueutil --is-connected "Surface di Francesco")
    if [ "$CONNECTED" = "1" ]; then
        echo -n 🎧
    else
        echo -n 🔈
    fi
fi
