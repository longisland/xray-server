#!/bin/sh
cd /xray

apk update
apk add --no-cache wget unzip curl

wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o ./Xray-linux-64.zip
rm ./Xray-linux-64.zip

PORT=${PORT:-8080}
ID=${ID:-"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}
WSPATH=${WSPATH:-"/api/v2/stream"}

# XHTTP (SplitHTTP) - рекомендован для CDN
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
      "network": "xhttp",
      "xhttpSettings": {
        "path": "${WSPATH}",
        "mode": "auto"
      }
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
  }],
  "outbounds": [{"protocol": "freedom"}]
}
XRAYEOF

echo "=== XHTTP Config ==="
cat ./config.json
exec ./xray run -config ./config.json
