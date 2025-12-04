#!/bin/sh

# Test outbound on startup
echo "Testing outbound connection..."
OUTBOUND_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "BLOCKED")
echo "Outbound IP: $OUTBOUND_IP"

# Write to file for later check
echo "$OUTBOUND_IP" > /tmp/outbound_ip.txt

nginx &
exec xray run -config /etc/xray/config.json
