#!/bin/bash
# ngrok-location-check.sh
# Exit 0 if device is on an allowed WiFi network, exit 1 otherwise.
# Used as ExecCondition= for the ngrok systemd service.

ALLOWED_SSIDS_FILE="/opt/fulfil/ngrok-allowed-ssids"

# Fail-open if no allow-list file exists (backward compat)
if [ ! -f "$ALLOWED_SSIDS_FILE" ]; then
    exit 0
fi

# Get current SSID (handles SSIDs with spaces)
CURRENT_SSID=$(iw wlan0 link 2>/dev/null | sed -n 's/^\s*SSID: //p')

if [ -z "$CURRENT_SSID" ]; then
    echo "ngrok-location-check: WiFi not connected"
    exit 1
fi

# Check if current SSID is in the allowed list (one SSID per line, exact match)
if grep -qxF "$CURRENT_SSID" "$ALLOWED_SSIDS_FILE"; then
    echo "ngrok-location-check: SSID '$CURRENT_SSID' is allowed"
    exit 0
else
    echo "ngrok-location-check: SSID '$CURRENT_SSID' is NOT allowed"
    exit 1
fi
