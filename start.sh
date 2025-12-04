#!/bin/sh
cd /xray

apk update
apk add --no-cache wget unzip curl nginx

# Создаём фейковый сайт
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <title>Cloud API Service</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        h1 { color: #333; }
        .status { color: green; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Cloud API Service</h1>
        <p class="status">✓ Service is running</p>
        <p>API Version: 2.1.0</p>
        <p>Status: Healthy</p>
        <hr>
        <p><small>© 2024 Cloud Services Inc.</small></p>
    </div>
</body>
</html>
HTMLEOF

# nginx конфигурация - проксирует VPN на скрытый path
cat > /etc/nginx/nginx.conf << 'NGINXEOF'
worker_processes 1;
error_log /dev/stderr warn;
pid /run/nginx.pid;
daemon off;

events { worker_connections 256; }

http {
    access_log off;
    
    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }

    server {
        listen 8080;
        
        # Фейковый сайт
        location / {
            root /var/www/html;
            index index.html;
        }
        
        # Скрытый VPN endpoint - выглядит как API
        location /api/v3/websocket/connect {
            proxy_pass http://127.0.0.1:10000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $host;
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
        }
    }
}
NGINXEOF

# Скачиваем Xray
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o ./Xray-linux-64.zip
rm ./Xray-linux-64.zip

ID=${ID:-"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}

# Xray на внутреннем порту
cat > ./config.json <<XRAYEOF
{
  "log": {"loglevel": "info"},
  "dns": {"servers": ["8.8.8.8", "1.1.1.1"]},
  "inbounds": [{
    "port": 10000,
    "listen": "127.0.0.1",
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "${ID}"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "security": "none",
      "wsSettings": {
        "path": "/api/v3/websocket/connect"
      }
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
  }],
  "outbounds": [{"protocol": "freedom"}]
}
XRAYEOF

echo "=== Fake Website + Hidden VPN ==="
cat ./config.json

# Запускаем xray в фоне
./xray run -config ./config.json &

# Запускаем nginx на переднем плане
exec nginx
