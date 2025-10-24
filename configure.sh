#!/bin/sh
set -e

echo "Installing v2ray..."
TMP_DIR=$(mktemp -d)
curl -L -H "Cache-Control: no-cache" -o "$TMP_DIR/v2ray.zip" https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
unzip -q "$TMP_DIR/v2ray.zip" -d "$TMP_DIR"
install -m 755 "$TMP_DIR/v2ray" /usr/local/bin/v2ray
rm -rf "$TMP_DIR"

echo "Installing nginx..."
apk add --no-cache nginx

echo "Creating v2ray config..."
install -d /usr/local/etc/v2ray

# Optimized config for censorship bypass and speed
cat << EOF > /usr/local/etc/v2ray/config.json
{
  "log": {
    "loglevel": "warning"
  },
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
        "security": "none",
        "wsSettings": {
          "path": "/vless",
          "headers": {
            "Host": ""
          }
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIPv4"
      },
      "streamSettings": {
        "sockopt": {
          "tcpFastOpen": true,
          "tcpKeepAliveInterval": 30,
          "tcpNoDelay": true
        }
      }
    }
  ],
  "policy": {
    "levels": {
      "0": {
        "bufferSize": 0
      }
    }
  },
  "transport": {
    "wsSettings": {
      "connectionReuse": true
    }
  }
}
EOF

# Nginx optimized for speed and reliability
cat << 'NGINX' > /etc/nginx/http.d/default.conf
server {
    listen 8080;
    
    # Health check endpoint
    location / {
        return 200 "Hello World\n";
        add_header Content-Type text/plain;
    }
    
    # VLESS WebSocket with optimizations
    location /vless {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        
        # WebSocket headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # Optimized timeouts for speed
        proxy_connect_timeout 10s;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
        
        # Disable buffering for lower latency
        proxy_buffering off;
        proxy_request_buffering off;
        
        # TCP optimizations
        tcp_nodelay on;
        tcp_nopush on;
    }
}
NGINX

# Start nginx
nginx

# Start v2ray
echo "Starting v2ray..."
exec /usr/local/bin/v2ray run -c /usr/local/etc/v2ray/config.json
