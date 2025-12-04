#!/bin/sh
cd /xray

apk update
apk add --no-cache wget unzip curl socat

# Тест исходящего соединения и сохранение результата
echo "=== Testing outbound connectivity ===" > /tmp/diag.txt
echo "DNS test:" >> /tmp/diag.txt
nslookup google.com >> /tmp/diag.txt 2>&1 || echo "DNS FAILED" >> /tmp/diag.txt
echo "" >> /tmp/diag.txt
echo "Curl test:" >> /tmp/diag.txt
curl -s https://httpbin.org/ip >> /tmp/diag.txt 2>&1 || echo "CURL FAILED" >> /tmp/diag.txt
echo "" >> /tmp/diag.txt
echo "IP check:" >> /tmp/diag.txt
curl -s https://api.ipify.org >> /tmp/diag.txt 2>&1
echo "==================================" >> /tmp/diag.txt

# Запускаем простой HTTP сервер для диагностики на порту 8081
(while true; do
  echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n$(cat /tmp/diag.txt)" | nc -l -p 8081 -q 1 2>/dev/null
done) &

# Скачиваем Xray
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o ./Xray-linux-64.zip
rm ./Xray-linux-64.zip

PORT=${PORT:-8080}
ID=${ID:-"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}
WSPATH=${WSPATH:-"/api/v2/stream"}

cat > ./config.json <<XRAYEOF
{
  "log": {
    "loglevel": "warning"
  },
  "dns": {
    "servers": ["8.8.8.8", "1.1.1.1"]
  },
  "inbounds": [{
    "port": ${PORT},
    "listen": "0.0.0.0",
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "${ID}"}],
      "decryption": "none",
      "fallbacks": [
        {"dest": 8081}
      ]
    },
    "streamSettings": {
      "network": "ws",
      "security": "none",
      "wsSettings": {"path": "${WSPATH}"}
    },
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"]
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
XRAYEOF

cat /tmp/diag.txt
exec ./xray run -config ./config.json
