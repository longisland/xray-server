FROM alpine:latest

# Install xray
RUN apk add --no-cache curl unzip ca-certificates tzdata && \
    curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip /tmp/xray.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && \
    rm /tmp/xray.zip

# Create config directory
RUN mkdir -p /etc/xray

# Copy config
COPY config.json /etc/xray/config.json

# Expose port (Koyeb expects 8080)
EXPOSE 8080

# Health check endpoint will be handled by xray fallback
CMD ["xray", "run", "-config", "/etc/xray/config.json"]
