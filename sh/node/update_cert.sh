#!/bin/bash

# 定义证书路径
CERT_KEY_PATH="/etc/V2bX/cert.key"
FULLCHAIN_PATH="/etc/V2bX/fullchain.cer"

# 定义 GitHub 上证书的 URL
CERT_KEY_URL="https://raw.githubusercontent.com/CraftedInCode/tools/main/sh/node/cert.key"
FULLCHAIN_URL="https://raw.githubusercontent.com/CraftedInCode/tools/main/sh/node/fullchain.cer"

# 下载最新证书
echo "Downloading new SSL certificate..."

if curl -o "$CERT_KEY_PATH" "$CERT_KEY_URL"; then
    echo "Successfully downloaded cert.key."
else
    echo "Failed to download cert.key."
    exit 1
fi

if curl -o "$FULLCHAIN_PATH" "$FULLCHAIN_URL"; then
    echo "Successfully downloaded fullchain.cer."
else
    echo "Failed to download fullchain.cer."
    exit 1
fi

# 设置权限
chmod 600 "$CERT_KEY_PATH" "$FULLCHAIN_PATH"
echo "Permissions set for the new certificates."

# 重启 V2bX 服务
echo "Restarting V2bX..."
if v2bx restart; then
    echo "V2bX restarted successfully."
else
    echo "Failed to restart V2bX."
    exit 1
fi

echo "SSL certificate replacement and V2bX restart completed."
