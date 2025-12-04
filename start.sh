#!/bin/sh
cd /xray

apk update
apk add --no-cache wget unzip curl

wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o ./Xray-linux-64.zip
rm ./Xray-linux-64.zip

PORT=${PORT:-8080}
ID=${ID:-"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}
WSPATH=${WSPATH:-"/relay"}

# ХИТРОСТЬ: Koyeb принимает VLESS+WS, но выход через SOCKS к localhost
# Это создаёт цепочку и может обойти DPI
cat > ./config.json <<XRAYEOF
{
  "log": {"loglevel": "info"},
  "dns": {
    "servers": ["8.8.8.8", "1.1.1.1"],
    "queryStrategy": "UseIP"
  },
  "inbounds": [{
    "port": ${PORT},
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "${ID}"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "security": "none",
      "wsSettings": {
        "path": "${WSPATH}",
        "maxEarlyData": 2048,
        "earlyDataHeaderName": "Sec-WebSocket-Protocol"
      }
    },
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls", "quic"],
      "routeOnly": false
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {
      "domainStrategy": "UseIPv4"
    },
    "tag": "direct"
  }],
  "policy": {
    "levels": {
      "0": {
        "handshake": 10,
        "connIdle": 300,
        "uplinkOnly": 5,
        "downlinkOnly": 30,
        "bufferSize": 10240
      }
    }
  }
}
XRAYEOF

echo "=== WebSocket with Early Data + Extended Timeouts ==="
cat ./config.json
exec ./xray run -config ./config.json
