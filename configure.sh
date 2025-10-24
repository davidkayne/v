#!/bin/sh
set -e

echo "Installing v2ray..."
TMP_DIR=$(mktemp -d)
curl -L -H "Cache-Control: no-cache" -o "$TMP_DIR/v2ray.zip" https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
unzip "$TMP_DIR/v2ray.zip" -d "$TMP_DIR"
install -m 755 "$TMP_DIR/v2ray" /usr/local/bin/v2ray
rm -rf "$TMP_DIR"

echo "Creating v2ray config..."
install -d /usr/local/etc/v2ray

# Create v2ray config with HTTP inbound for fallback
cat << EOF > /usr/local/etc/v2ray/config.json
{
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$ID",
            "level": 0
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 8080
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    },
    {
      "port": 8080,
      "listen": "127.0.0.1",
      "protocol": "http",
      "settings": {
        "timeout": 0
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

echo "Starting v2ray..."
exec /usr/local/bin/v2ray run -c /usr/local/etc/v2ray/config.json
