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

# Полная конфигурация с DNS и routing
cat > ./config.json <<XRAYEOF
{
  "log": {
    "loglevel": "info",
    "access": "/dev/stdout",
    "error": "/dev/stderr"
  },
  "dns": {
    "servers": [
      "8.8.8.8",
      "8.8.4.4",
      "1.1.1.1"
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
        "path": "${WSPATH}",
        "headers": {}
      }
    },
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"]
    }
  }],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIP"
      },
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
      }
    ]
  }
}
XRAYEOF

echo "=== Xray Config ==="
cat ./config.json
echo "==================="
echo "Starting Xray..."

# Запускаем Xray
exec ./xray run -config ./config.json
