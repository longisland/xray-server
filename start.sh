#!/bin/sh

PORT=${PORT:-8080}
UUID=${UUID:-"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}
WSPATH=${WSPATH:-"/tunnel"}

# sing-box configuration for VLESS over WebSocket
cat > /tmp/config.json << CONFIGEOF
{
  "log": {"level": "info"},
  "dns": {
    "servers": [
      {"address": "8.8.8.8"},
      {"address": "1.1.1.1"}
    ]
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "0.0.0.0",
      "listen_port": ${PORT},
      "users": [
        {"uuid": "${UUID}"}
      ],
      "transport": {
        "type": "ws",
        "path": "${WSPATH}",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
CONFIGEOF

echo "=== sing-box config ==="
cat /tmp/config.json
echo "======================"

exec sing-box run -c /tmp/config.json
