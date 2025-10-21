#!/bin/sh
set -e
TMP_DIR=$(mktemp -d)
curl -L -H "Cache-Control: no-cache" -o "$TMP_DIR/v2ray.zip" https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
unzip "$TMP_DIR/v2ray.zip" -d "$TMP_DIR"
install -m 755 "$TMP_DIR/v2ray" /usr/local/bin/v2ray
rm -rf "$TMP_DIR"
install -d /usr/local/etc/v2ray
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
            "flow": "",
            "level": 0,
            "email": "test@example.org"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF
# Start V2Ray in background
/usr/local/bin/v2ray run -c /usr/local/etc/v2ray/config.json &
# Start lightweight HTTP server on port 8080 for keep-alive pings
cd /tmp && python3 -m http.server 8080
