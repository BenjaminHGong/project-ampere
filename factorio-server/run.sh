#!/bin/bash
# ~/run.sh

# Configuration
FACTORCORD_DIR="/home/ubuntu/factorio-server/FactoCord3"
SESSION_NAME="factorio"

# 1. Clean up any stuck locks before starting
rm -f /home/ubuntu/factorio-server/factorio/.lock

# 2. Check if screen is already running
if screen -list | grep -q "\.${SESSION_NAME}"; then
    echo "FactoCord is already running in screen. Use 'screen -r $SESSION_NAME' to see it."
else
    echo "Starting FactoCord with Auto-Restart..."
    screen -dmS "$SESSION_NAME" bash -c "
        cd \"$FACTORCORD_DIR\"
        while true; do
            echo '--- Cleaning up Ghost Processes ---'
            # Kill any lingering factorio bins and delete the lock file
            pkill -9 factorio
            rm -f ../factorio/.lock 

            echo '--- Launching FactoCord ---'
            ./FactoCord3
            
            echo 'Crash detected. Cleaning up and restarting in 5s...'
            sleep 5
        done
    "
    echo "Session '$SESSION_NAME' created. Server is booting."
fi