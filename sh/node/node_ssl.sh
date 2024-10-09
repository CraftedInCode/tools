#!/bin/bash

# 定义下载链接和目标文件路径
CERT_URL="https://github.com/CraftedInCode/tools/blob/main/sh/update-ssl/node.crt"
KEY_URL="https://github.com/CraftedInCode/tools/blob/main/sh/update-ssl/node.key"
DEST_DIR="/etc/V2bX"
CERT_FILE="$DEST_DIR/fullchain.cer"
KEY_FILE="$DEST_DIR/cert.key"

# 删除旧的证书和密钥文件
echo "正在删除旧的证书和密钥文件..."
rm -f "$CERT_FILE"
rm -f "$KEY_FILE"
if [ $? -eq 0 ]; then
    echo "旧的证书和密钥文件删除成功。"
else
    echo "删除旧的证书和密钥文件失败。" >&2
    exit 1
fi

# 下载新的证书和密钥
echo "正在下载新的证书..."
wget -O "$CERT_FILE" "$CERT_URL"
if [ $? -eq 0 ]; then
    echo "证书下载成功，已保存到 $CERT_FILE。"
else
    echo "证书下载失败。" >&2
    exit 1
fi

echo "正在下载新的密钥..."
wget -O "$KEY_FILE" "$KEY_URL"
if [ $? -eq 0 ]; then
    echo "密钥下载成功，已保存到 $KEY_FILE。"
else
    echo "密钥下载失败。" >&2
    exit 1
fi

# 重启V2bX服务
echo "尝试重启V2bX服务..."
systemctl restart V2bX
if [ $? -eq 0 ]; then
    echo "V2bX服务已成功重启。"
else
    echo "V2bX服务重启失败。" >&2
    exit 1
fi
