FROM alpine:latest

# Install required packages
RUN apk add --no-cache ca-certificates curl unzip bash

# Download and install V2Ray
RUN mkdir /tmp/v2ray && \
    curl -L -H "Cache-Control: no-cache" -o /tmp/v2ray/v2ray.zip https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip && \
    unzip /tmp/v2ray/v2ray.zip -d /tmp/v2ray && \
    install -m 755 /tmp/v2ray/v2ray /usr/local/bin/v2ray && \
    install -m 755 /tmp/v2ray/v2ctl /usr/local/bin/v2ctl && \
    rm -rf /tmp/v2ray

# Create config directory
RUN mkdir -p /usr/local/etc/v2ray

# Create startup script
RUN cat > /start.sh << 'EOF'
#!/bin/sh

# Get UUID from environment or use default
UUID=${UUID:-"472523ae-a4a7-42d9-92a1-e302ddba9757"}

# Get PORT from environment (Koyeb sets this automatically)
PORT=${PORT:-8080}

echo "Starting V2Ray VLESS server..."
echo "Port: $PORT"
echo "UUID: $UUID"

# Create V2Ray configuration
cat << CONFIG > /usr/local/etc/v2ray/config.json
{
    "inbounds": [
        {
            "port": $PORT,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID", 
                        "flow": "",
                        "level": 0,
                        "email": "user@example.org"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/$UUID"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
CONFIG

echo "Configuration created. Starting V2Ray..."

# Run V2Ray
exec /usr/local/bin/v2ray run -config /usr/local/etc/v2ray/config.json
EOF

# Make startup script executable
RUN chmod +x /start.sh

# Expose port (Koyeb will use the PORT env variable)
EXPOSE 8080

# Start the service
CMD ["/start.sh"]
