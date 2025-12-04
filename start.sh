#!/bin/sh
cd /xray

apk update
apk add --no-cache wget unzip curl

wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o ./Xray-linux-64.zip
rm ./Xray-linux-64.zip

PORT=${PORT:-8080}
PASSWORD=${PASSWORD:-"HoldemVPN2024SecurePass"}
WSPATH=${WSPATH:-"/api/v2/stream"}

# Trojan over WebSocket - лучшая маскировка
cat > ./config.json <<XRAYEOF
{
  "log": {"loglevel": "info"},
  "dns": {"servers": ["8.8.8.8", "1.1.1.1"]},
  "inbounds": [{
    "port": ${PORT},
    "protocol": "trojan",
    "settings": {
      "clients": [{"password": "${PASSWORD}"}]
    },
    "streamSettings": {
      "network": "ws",
      "security": "none",
      "wsSettings": {
        "path": "${WSPATH}"
      }
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
  }],
  "outbounds": [{"protocol": "freedom"}]
}
XRAYEOF

echo "=== Trojan over WebSocket Config ==="
cat ./config.json
exec ./xray run -config ./config.json
