#!/bin/sh
cd /xray

apk update
apk add --no-cache wget unzip curl nginx

mkdir -p /var/www/html
echo '{"status":"ok","version":"2.0"}' > /var/www/html/health.json

# nginx как TCP relay к VPS
cat > /etc/nginx/nginx.conf << 'NGINXEOF'
worker_processes 1;
error_log /dev/stderr warn;
pid /run/nginx.pid;
daemon off;

events { worker_connections 1024; }

http {
    access_log off;
    
    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }

    server {
        listen 8080;
        
        location /health {
            return 200 '{"status":"ok"}';
            add_header Content-Type application/json;
        }
        
        location / {
            return 200 'OK';
            add_header Content-Type text/plain;
        }
        
        # WebSocket relay к VPS (Aeza)
        location /vless {
            proxy_pass http://77.221.156.175:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
            proxy_buffering off;
            proxy_cache off;
        }
    }
}
NGINXEOF

echo "=== Koyeb as Relay to VPS ==="
cat /etc/nginx/nginx.conf

exec nginx
