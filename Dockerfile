FROM alpine:latest

# Установка wstunnel и sing-box
RUN apk add --no-cache curl wget tar gzip

# Скачиваем sing-box (альтернатива xray с лучшей реализацией)
RUN wget -q https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz && \
    tar -xzf sing-box-1.10.1-linux-amd64.tar.gz && \
    mv sing-box-1.10.1-linux-amd64/sing-box /usr/local/bin/ && \
    rm -rf sing-box-*

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080
CMD ["/start.sh"]
