#!/bin/sh
cd /xray

apk update
apk add --no-cache wget unzip curl busybox-extras

mkdir -p /www

# Тест исходящего соединения
{
  echo "=== Koyeb Outbound Connectivity Test ==="
  echo "Date: $(date)"
  echo ""
  echo "DNS Test (google.com):"
  nslookup google.com 2>&1 || echo "FAILED"
  echo ""
  echo "HTTP Test (httpbin.org/ip):"
  curl -s --connect-timeout 5 https://httpbin.org/ip 2>&1 || echo "FAILED"
  echo ""
  echo "My IP:"
  curl -s --connect-timeout 5 https://api.ipify.org 2>&1 || echo "FAILED"
  echo ""
  echo "=== End Test ==="
} > /www/index.html

# HTTP сервер для диагностики
httpd -f -p 8081 -h /www &
echo "Diagnostic server started on 8081"

# Скачиваем Xray
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o ./Xray-linux-64.zip
rm ./Xray-linux-64.zip

PORT=${PORT:-8080}
ID=${ID:-"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}
WSPATH=${WSPATH:-"/api/v2/stream"}

cat > ./config.json <<XRAYEOF
{
  "log": {"loglevel": "warning"},
  "dns": {"servers": ["8.8.8.8", "1.1.1.1"]},
  "inbounds": [{
    "port": ${PORT},
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "${ID}"}],
      "decryption": "none",
      "fallbacks": [{"dest": 8081}]
    },
    "streamSettings": {
      "network": "ws",
      "security": "none",
      "wsSettings": {"path": "${WSPATH}"}
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
  }],
  "outbounds": [{"protocol": "freedom"}]
}
XRAYEOF

cat /www/index.html
exec ./xray run -config ./config.json
