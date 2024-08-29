#!/bin/bash

# 定义下载链接和目标文件路径
CERT_URL="https://drive.yd-zl.com/d/local/sh/update-ssl/yunduanconnect.cer?sign=K16M1sTDB_788M3YDJ--6URCtj3PH_VBFrk_AAsHT0M=:0"
KEY_URL="https://drive.yd-zl.com/d/local/sh/update-ssl/yunduanconnect.key?sign=ro1_Gb7iwWo-uwsf5jbehti78xi5B8-LVQ2Lh74NioM=:0"
DEST_DIR="/root/gost_cert"
CERT_FILE="$DEST_DIR/cert.pem"
KEY_FILE="$DEST_DIR/key.pem"

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

# 重启Gost服务并重新加载配置
echo "正在重启Gost服务并重新加载配置..."
rm -rf /etc/gost/config.json
if [ $? -eq 0 ]; then
    echo "旧的配置文件删除成功。"
else
    echo "删除旧的配置文件失败。" >&2
    exit 1
fi

# 执行重新生成配置的函数
confstart
writeconf
conflast
if [ $? -eq 0 ]; then
    echo "配置文件生成成功。"
else
    echo "生成配置文件失败。" >&2
    exit 1
fi

# 重启Gost服务
systemctl restart gost
if [ $? -eq 0 ]; then
    echo "Gost服务已成功重启。"
else
    echo "Gost服务重启失败。" >&2
    exit 1
fi
