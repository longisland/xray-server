#!/bin/sh
cd /xray

# Устанавливаем зависимости
apk update
apk add --no-cache wget unzip

# Скачиваем Xray
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o ./Xray-linux-64.zip
rm ./Xray-linux-64.zip

# Переменные окружения
PORT=${PORT:-8080}
ID=${ID:-"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}
WSPATH=${WSPATH:-"/api/v2/stream"}

# Генерируем config.json - ЧИСТЫЙ WebSocket без fallback!
cat > ./config.json <<XRAYEOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": ${PORT},
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
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
XRAYEOF

echo "Starting Xray with config:"
cat ./config.json

# Запускаем Xray
./xray run -config ./config.json
