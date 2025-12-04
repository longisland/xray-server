#!/bin/sh
cd /xray

apk update
apk add --no-cache wget unzip curl

wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o ./Xray-linux-64.zip
rm ./Xray-linux-64.zip

PORT=${PORT:-8080}
ID=${ID:-"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}

# HTTP/2 транспорт - нативная поддержка Koyeb!
# Маскируется под обычный HTTP/2 API трафик
cat > ./config.json <<XRAYEOF
{
  "log": {"loglevel": "info"},
  "dns": {"servers": ["8.8.8.8", "1.1.1.1"]},
  "inbounds": [{
    "port": ${PORT},
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "${ID}"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "h2",
      "httpSettings": {
        "path": "/grpc.health.v1.Health/Check",
        "host": ["xray-vpn-myself234234234-3a29630f.koyeb.app"],
        "read_idle_timeout": 60,
        "health_check_timeout": 30
      }
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
  }],
  "outbounds": [{"protocol": "freedom"}]
}
XRAYEOF

echo "=== HTTP/2 Config (masked as gRPC health check) ==="
cat ./config.json
exec ./xray run -config ./config.json
