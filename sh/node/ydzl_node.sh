#!/bin/bash

# 定义颜色变量
GREEN='\033[0;32m'
NC='\033[0m' # 无颜色

# 更新 Debian 软件包和安装必要工具
function Debian_update() {
    echo -e "${GREEN}正在更新 Debian 软件包...${NC}"
    echo -e "${GREEN}更新软件包列表...${NC}"
    sudo apt update
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}软件包列表更新失败！${NC}"
        exit 1
    fi
    echo -e "${GREEN}升级所有已安装的软件包...${NC}"
    sudo apt upgrade -y
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}软件包升级失败！${NC}"
        exit 1
    fi
    echo -e "${GREEN}进行全面升级...${NC}"
    sudo apt full-upgrade -y
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}全面升级失败！${NC}"
        exit 1
    fi
    echo -e "${GREEN}清理不再需要的包...${NC}"
    sudo apt autoremove -y
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}自动清理失败！${NC}"
        exit 1
    fi
    echo -e "${GREEN}安装必要的工具...${NC}"
    sudo apt install -y iproute2 net-tools
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}工具安装失败！${NC}"
        exit 1
    fi
    echo -e "${GREEN}软件包和工具安装完成！${NC}"
}


# 下载并安装 V2bX
function install_v2bx() {
    echo -e "${GREEN}下载并安装 V2bX...${NC}"
    
    wget -N https://raw.githubusercontent.com/wyx2685/V2bX-script/master/install.sh
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}下载 V2bX 安装脚本失败！${NC}"
        exit 1
    fi
    
    sudo bash install.sh
    if [ $? -ne 0 ];then
        echo -e "${GREEN}V2bX 安装失败！${NC}"
        exit 1
    fi
    echo -e "${GREEN}V2bX 下载和安装成功！${NC}"
}

#生成/etc/V2bX/config.json
function update_v2bx_config() {
    echo -e "${GREEN}请输入 NodeID:${NC}"
    read node_id
    echo -e "${GREEN}请输入 CertDomain 的前缀 (例如: hk1):${NC}"
    read cert_domain_prefix

    config_path="/etc/V2bX/config.json"
    cert_domain_suffix=".ccjz4nmym6qedf3muvprkn6e73rgad3ks3uj1nuocfpn46vyquh2zj070b3uf12.yunduanconnect.com"
    full_cert_domain="${cert_domain_prefix}${cert_domain_suffix}"

    # 更新配置文件
    cat > $config_path <<EOL
{
    "Log": {
        "Level": "error",
        "Output": ""
    },
    "Cores": [
        {
            "Type": "sing",
            "Log": {
                "Level": "error",
                "Timestamp": true
            },
            "NTP": {
                "Enable": false,
                "Server": "time.apple.com",
                "ServerPort": 0
            },
            "OriginalPath": "/etc/V2bX/sing_origin.json"
        }
    ],
    "Nodes": [{
        "Core": "sing",
        "ApiHost": "https://node-2ua3ahgcmg9xj7nouaogyf8zjegi-aeuxq8ejcdpnovu4y1kzshh6xg.r2kxwuac-cb31fac0h-612tt1bm-bc7kvqvfh-ggz3uqe-affdtjq4-qa7jb1kz.xyz",
        "ApiKey": "sally-pave-unsnarl-mimi",
        "NodeID": $node_id,
        "NodeType": "trojan",
        "Timeout": 30,
        "ListenIP": "::",
        "SendIP": "0.0.0.0",
        "DeviceOnlineMinTraffic": 1000,
        "TCPFastOpen": true,
        "SniffEnabled": true,
        "EnableDNS": true,
        "CertConfig": {
            "CertMode": "self",
            "RejectUnknownSni": false,
            "CertDomain": "$full_cert_domain",
            "CertFile": "/etc/V2bX/fullchain.cer",
            "KeyFile": "/etc/V2bX/cert.key",
            "Email": "v2bx@github.com",
            "Provider": "cloudflare",
            "DNSEnv": {
                "EnvName": "env1"
            }
        }
    }]
}
EOL

    echo -e "${GREEN}配置文件已成功更新${NC}"
}


# 生成 Singbox 配置文件
function generate_sing_origin_json() {
    # 备份现有的 sing_origin.json 文件
    cp /etc/V2bX/sing_origin.json /etc/V2bX/sing_origin.json.bak

    # 读取 PrivateKey 和 Reserved 值
    private_key=$(grep '^PrivateKey' /etc/wireguard/warp.conf | awk -F '= ' '{print $2}')
    reserved=$(grep '^#Reserved' /etc/wireguard/warp.conf | awk -F '= ' '{print $2}' | tr -d '[]')

    # 生成新的 sing_origin.json 文件
    cat <<EOF > /etc/V2bX/sing_origin.json
{
  "dns": {
    "servers": [
      {
        "tag": "cloudflare_ipv4",
        "address": "1.1.1.1",
        "strategy": "prefer_ipv4"
      },
      {
        "tag": "cloudflare_ipv4_backup",
        "address": "1.0.0.1",
        "strategy": "prefer_ipv4"
      },
      {
        "tag": "cloudflare_ipv6",
        "address": "2606:4700:4700::1111",
        "strategy": "prefer_ipv6"
      },
      {
        "tag": "cloudflare_ipv6_backup",
        "address": "2606:4700:4700::1001",
        "strategy": "prefer_ipv6"
      }
    ]
  },
  "outbounds": [
    {
      "tag": "direct",
      "type": "direct",
      "domain_strategy": "prefer_ipv4"
    },
    {
      "type": "block",
      "tag": "block"
    },
    {
      "type": "wireguard",
      "tag": "warp",
      "server": "engage.cloudflareclient.com",
      "server_port": 2408,
      "local_address": ["172.16.0.2/32"],
      "private_key": "$private_key",
      "peer_public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
      "reserved": [$reserved],
      "mtu": 1420
    }
  ],
  "route": {
    "rules": [
      {
        "ip_is_private": true,
        "outbound": "block"
      },
      {
        "rule_set": [
          "geosite-google"
        ],
        "outbound": "direct"
      },
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "outbound": "block"
      },
      {
        "rule_set": [
          "geosite-cn",
          "geoip-cn"
        ],
        "outbound": "warp"
      },
      {
        "domain_keyword": [
          "chatgpt",
          "openai",
          "netflix"
        ],
        "outbound": "warp"
      },
      {
        "domain_keyword": [
          "hongkongtrader",
          "yd-zl",
          "云端智联",
          "yunduanzhilian"
        ],
        "outbound": "direct"
      },
      {
        "domain_regex": [
          "(api|ps|sv|offnavi|newvector|ulog.imap|newloc)(.map|).(baidu|n.shifen).com",
          "(.+.|^)(360|so).(cn|com)",
          "(Subject|HELO|SMTP)",
          "(torrent|.torrent|peer_id=|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=)",
          "(^.@)(guerrillamail|guerrillamailblock|sharklasers|grr|pokemail|spam4|bccto|chacuo|027168).(info|biz|com|de|net|org|me|la)",
          "(.?)(xunlei|sandai|Thunder|XLLiveUD)(.)",
          "(..||)(dafahao|mingjinglive|botanwang|minghui|dongtaiwang|falunaz|epochtimes|ntdtv|falundafa|falungong|wujieliulan|zhengjian).(org|com|net)",
          "(ed2k|.torrent|peer_id=|announce|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=|magnet:|xunlei|sandai|Thunder|XLLiveUD|bt_key)",
          "(.+.|^)(360).(cn|com|net)",
          "(.*.||)(guanjia.qq.com|qqpcmgr|QQPCMGR)",
          "(.*.||)(rising|kingsoft|duba|xindubawukong|jinshanduba).(com|net|org)",
          "(.*.||)(netvigator|torproject).(com|cn|net|org)",
          "(..||)(visa|mycard|gash|beanfun|bank).",
          "(.*.||)(gov|12377|12315|talk.news.pts.org|creaders|zhuichaguoji|efcc.org|cyberpolice|aboluowang|tuidang|epochtimes|zhengjian|110.qq|mingjingnews|inmediahk|xinsheng|breakgfw|chengmingmag|jinpianwang|qi-gong|mhradio|edoors|renminbao|soundofhope|xizang-zhiye|bannedbook|ntdtv|12321|secretchina|dajiyuan|boxun|chinadigitaltimes|dwnews|huaglad|oneplusnews|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk|eu|info|me)",
          "(.*.||)(miaozhen|cnzz|talkingdata|umeng).(cn|com)",
          "(.*.||)(mycard).(com|tw)",
          "(.*.||)(gash).(com|tw)",
          "(.bank.)",
          "(.*.||)(pincong).(rocks)",
          "(.*.||)(taobao).(com)",
          "(.*.||)(laomoe|jiyou|ssss|lolicp|vv1234|0z|4321q|868123|ksweb|mm126).(com|cloud|fun|cn|gs|xyz|cc)",
          "(flows|miaoko).(pages).(dev)"
        ],
        "outbound": "block"
      },
      {
        "outbound": "direct",
        "network": [
          "udp",
          "tcp"
        ]
      }
    ],
    "rule_set": [
      {
        "tag": "geoip-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-category-ads-all",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-google",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-google.srs",
        "download_detour": "direct"
      }
    ]
  },
  "experimental": {
    "cache_file": {
      "enabled": true
    }
  }
}
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Singbox 配置文件生成成功。${NC}"
    else
        echo -e "${RED}生成 Singbox 配置文件失败。${NC}"
        exit 1
    fi
}

function download_ssl() {
    # Step 5: 下载 SSL 证书和密钥
    CERT_URL="https://drive.yd-zl.com/d/local/sh/update-ssl/yunduanconnect.cer?sign=K16M1sTDB_788M3YDJ--6URCtj3PH_VBFrk_AAsHT0M=:0"
    KEY_URL="https://drive.yd-zl.com/d/local/sh/update-ssl/yunduanconnect.key?sign=ro1_Gb7iwWo-uwsf5jbehti78xi5B8-LVQ2Lh74NioM=:0"
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
    if [ $? -eq 0 ];then
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

    echo -e "${GREEN}证书和密钥下载并配置完成。${NC}"
}


# Step 6: 开放所有端口
function open_all_ports() {
    echo "正在开放所有端口..."
    systemctl stop firewalld.service 2>/dev/null
    systemctl disable firewalld.service 2>/dev/null
    setenforce 0 2>/dev/null
    ufw disable 2>/dev/null
    iptables -P INPUT ACCEPT 2>/dev/null
    iptables -P FORWARD ACCEPT 2>/dev/null
    iptables -P OUTPUT ACCEPT 2>/dev/null
    iptables -t nat -F 2>/dev/null
    iptables -t mangle -F 2>/dev/null
    iptables -F 2>/dev/null
    iptables -X 2>/dev/null
    netfilter-persistent save 2>/dev/null
    echo -e "${GREEN}所有端口已开放。${NC}"
}

# Step 7: 重启 V2bX 服务
function restart_V2bX_service() {
    echo "尝试重启 V2bX 服务..."
    systemctl restart V2bX
    if [ $? -eq 0 ]; then
        echo "V2bX 服务已成功重启。"
    else
        echo "V2bX 服务重启失败。" >&2
        exit 1
    fi
}

#安装gost/生成配置+证书
function install_and_configure_gost() {
    echo -e "${GREEN}正在下载并安装 gost...${NC}"

    # 下载 gost 安装脚本
    wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/KANIKIG/Multi-EasyGost/master/gost.sh
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}下载 gost 安装脚本失败！${NC}" >&2
        exit 1
    fi

    # 修改权限并执行安装脚本
    chmod +x gost.sh
    ./gost.sh
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}gost 安装失败！${NC}" >&2
        exit 1
    fi

    # 自动选择 1 和 n
    echo -e "1\nn" | ./gost.sh
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}gost 配置失败！${NC}" >&2
        exit 1
    fi

    echo -e "${GREEN}gost 安装和配置成功。${NC}"

    # 安装完成后生成配置文件
    echo -e "${GREEN}请输入端口号（例如：11111）：${NC}"
    read -r port

    echo -e "${GREEN}请输入节点域名前缀（例如：us1）：${NC}"
    read -r node_prefix

    # 生成 config.json
    config_json_content=$(cat <<EOF
{
    "Debug": true,
    "Retries": 0,
    "ServeNodes": [
        "relay+wss://:${port}/${node_prefix}.ccjz4nmym6qedf3muvprkn6e73rgad3ks3uj1nuocfpn46vyquh2zj070b3uf12.yunduanconnect.com:8443?cert=/root/gost_cert/cert.pem&key=/root/gost_cert/key.pem"
    ]
}
EOF
    )

    echo -e "${GREEN}正在生成 /etc/gost/config.json...${NC}"
    echo "$config_json_content" | sudo tee /etc/gost/config.json > /dev/null
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}生成 /etc/gost/config.json 文件失败！${NC}" >&2
        exit 1
    fi

    echo -e "${GREEN}/etc/gost/config.json 文件生成成功。${NC}"

    # 生成 rawconf
    rawconf_content=$(cat <<EOF
decryptwss/${port}#${node_prefix}.ccjz4nmym6qedf3muvprkn6e73rgad3ks3uj1nuocfpn46vyquh2zj070b3uf12.yunduanconnect.com#8443
EOF
    )

    echo -e "${GREEN}正在生成 /etc/gost/rawconf...${NC}"
    echo "$rawconf_content" | sudo tee /etc/gost/rawconf > /dev/null
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}生成 /etc/gost/rawconf 文件失败！${NC}" >&2
        exit 1
    fi

    echo -e "${GREEN}/etc/gost/rawconf 文件生成成功。${NC}"

    # 生成证书目录并下载证书和密钥
    echo -e "${GREEN}正在生成证书目录并下载证书和密钥...${NC}"
    sudo mkdir -p /root/gost_cert
    wget -O /root/gost_cert/cert.pem "https://drive.yd-zl.com/d/local/sh/update-ssl/yunduanconnect.cer?sign=K16M1sTDB_788M3YDJ--6URCtj3PH_VBFrk_AAsHT0M=:0"
    wget -O /root/gost_cert/key.pem "https://drive.yd-zl.com/d/local/sh/update-ssl/yunduanconnect.key?sign=ro1_Gb7iwWo-uwsf5jbehti78xi5B8-LVQ2Lh74NioM=:0"
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}证书或密钥下载失败！${NC}" >&2
        exit 1
    fi

    # 停止 gost 服务并重读配置
    echo -e "${GREEN}正在停止 gost 服务...${NC}"
    sudo systemctl stop gost
    echo "Gost 服务已停止"

    echo -e "${GREEN}正在删除旧的配置文件...${NC}"
    sudo rm -rf /etc/gost/config.json

    echo -e "${GREEN}正在重读配置并重启 gost 服务...${NC}"
    echo 6 | ./gost.sh
    echo "Gost 服务已通过 gost.sh 重读配置并重启"
    echo -e "${GREEN}继续下一步${NC}"
}

# Step 8: 安装并启用 BBR
function install_and_enable_bbr() {
    echo "正在安装证书工具和下载 BBR 脚本..."
    apt-get install ca-certificates wget -y
    update-ca-certificates
    wget -O tcpx.sh "https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh"
    chmod +x tcpx.sh
    ./tcpx.sh

    echo -e "${GREEN}BBR 已配置完成。${NC}"
}

# Step 9: 再次重启 V2bX 服务
function restart_V2bX_service_again() {
    echo "尝试再次重启 V2bX 服务..."
    systemctl restart V2bX
    if [ $? -eq 0 ]; then
        echo "V2bX 服务已成功再次重启。"
    else
        echo "V2bX 服务再次重启失败。" >&2
        exit 1
    fi
}

# Step 10: 重启系统
function reboot_system() {
    echo -e "${GREEN}所有步骤完成，系统即将重启...${NC}"
    reboot
}

# 主函数调用所有步骤
function main() {
    Debian_update
    install_v2bx
    update_v2bx_config
    generate_sing_origin_json
    download_ssl
    open_all_ports
    restart_v2bx_service
    install_and_configure_gost
    install_and_enable_bbr
    restart_v2bx_service_again
    reboot_system
}


# 执行主函数
main
