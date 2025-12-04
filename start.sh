#!/bin/sh
cd /xray

# Устанавливаем зависимости
apk update
apk add --no-cache wget unzip curl

# Тест исходящего соединения
echo "=== Testing outbound connectivity ==="
echo "DNS test:"
nslookup google.com || echo "DNS FAILED"
echo ""
echo "HTTP test:"
curl -s -o /dev/null -w "HTTP: %{http_code}\n" https://httpbin.org/ip || echo "HTTP FAILED"
echo "=================================="

# Скачиваем Xray
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o ./Xray-linux-64.zip
rm ./Xray-linux-64.zip

# Переменные окружения
PORT=${PORT:-8080}
ID=${ID:-"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}
WSPATH=${WSPATH:-"/api/v2/stream"}

# Конфигурация
cat > ./config.json <<XRAYEOF
{
  "log": {
    "loglevel": "debug",
    "access": "/dev/stdout",
    "error": "/dev/stderr"
  },
  "dns": {
    "servers": [
      "8.8.8.8",
      "1.1.1.1",
      "localhost"
    ]
  },
  "inbounds": [{
    "port": ${PORT},
    "listen": "0.0.0.0",
    "protocol": "vless",
    "settings": {
      "clients": [{
        "id": "${ID}",
        "level": 0
      }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "security": "none",
      "wsSettings": {
        "path": "${WSPATH}"
      }
    },
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"],
      "routeOnly": false
    }
  }],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct",
      "settings": {}
    }
  ]
}
XRAYEOF

echo "=== Xray Config ==="
cat ./config.json
echo "==================="
echo "Starting Xray with debug logging..."

exec ./xray run -config ./config.json
