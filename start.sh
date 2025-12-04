#!/bin/sh
# Start simple HTTP server for health check on port 8081
cd /www && httpd -f -p 8081 &
# Start xray
exec xray run -config /etc/xray/config.json
