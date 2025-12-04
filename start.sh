#!/bin/sh
cd /xray

apk update
apk add --no-cache wget unzip curl

# Скачиваем Xray
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o ./Xray-linux-64.zip
rm ./Xray-linux-64.zip

PORT=${PORT:-8080}
ID=${ID:-"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}
WSPATH=${WSPATH:-"/api/v2/stream"}

# Тест исходящего соединения при старте
echo "=== Outbound Test ==="
echo "DNS:"
nslookup google.com 2>&1 | head -5
echo "HTTP:"
curl -s --connect-timeout 5 https://httpbin.org/ip 2>&1
echo "===================="

# Чистая конфигурация без fallback
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
      "network": "ws",
      "security": "none",
      "wsSettings": {"path": "${WSPATH}"}
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
  }],
  "outbounds": [{"protocol": "freedom", "settings": {}}]
}
XRAYEOF

echo "Config:"
cat ./config.json

exec ./xray run -config ./config.json
