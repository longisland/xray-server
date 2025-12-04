FROM alpine:latest
WORKDIR /xray

# Копируем скрипт запуска
COPY start.sh .
RUN chmod +x ./start.sh

EXPOSE 8080

ENTRYPOINT ["./start.sh"]
