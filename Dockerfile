FROM alpine:latest

# Install xray, nginx, and supervisor
RUN apk add --no-cache curl unzip ca-certificates tzdata nginx supervisor && \
    curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip /tmp/xray.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && \
    rm /tmp/xray.zip && \
    mkdir -p /etc/xray /run/nginx /var/log/supervisor

# Copy configs
COPY config.json /etc/xray/config.json
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf

EXPOSE 8080

CMD ["supervisord", "-c", "/etc/supervisord.conf"]
