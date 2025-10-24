#!/bin/sh
set -e

echo "Installing v2ray..."
TMP_DIR=$(mktemp -d)
curl -L -H "Cache-Control: no-cache" -o "$TMP_DIR/v2ray.zip" https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
unzip "$TMP_DIR/v2ray.zip" -d "$TMP_DIR"
install -m 755 "$TMP_DIR/v2ray" /usr/local/bin/v2ray
rm -rf "$TMP_DIR"

echo "Installing nginx..."
apk add --no-cache nginx

echo "Creating v2ray config..."
install -d /usr/local/etc/v2ray

# Create v2ray config - VLESS on WebSocket path /vless, listening on port 8001
cat << EOF > /usr/local/etc/v2ray/config.json
{
  "inbounds": [
    {
      "port": 8001,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$ID",
            "level": 0
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF

# Configure nginx
cat << 'NGINX' > /etc/nginx/http.d/default.conf
server {
    listen 8080;
    
    # Default location - return 200 OK for cron jobs
    location / {
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
    
    # WebSocket proxy for VLESS
    location /vless {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX

# Start nginx
nginx

# Start v2ray in background
/usr/local/bin/v2ray run -c /usr/local/etc/v2ray/config.json &

# Keep container running
wait

echo "Starting v2ray..."
exec /usr/local/bin/v2ray run -c /usr/local/etc/v2ray/config.json
