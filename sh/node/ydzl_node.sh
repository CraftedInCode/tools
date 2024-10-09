#!/bin/bash

# 检查是否以 root 权限运行
if [[ $EUID -ne 0 ]]; then
   echo "请使用 sudo 或 root 权限运行该脚本。" 
   exit 1
fi

# 定义颜色变量
GREEN='\033[0;32m'
NC='\033[0m' # 无颜色

# 配置路径
config_path="/etc/V2bX/config.json"

# 更新 Debian 软件包和安装必要工具
function Debian_update() {
    echo -e "${GREEN}正在更新 Debian 软件包...${NC}"
    apt update && apt upgrade -y && apt full-upgrade -y
    apt autoremove -y
    apt install -y iproute2 net-tools
    echo -e "${GREEN}软件包和工具安装完成！${NC}"
}

# 下载并安装 V2bX
function install_v2bx() {
    echo -e "${GREEN}下载并安装 V2BX...${NC}"
    
    wget -N https://raw.githubusercontent.com/wyx2685/V2bX-script/master/install.sh
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}下载 V2bX 安装脚本失败！${NC}"
        exit 1
    fi
    
    bash install.sh
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}V2bX 安装失败！${NC}"
        exit 1
    fi
    echo -e "${GREEN}V2bX 下载和安装成功！${NC}"
}

# 生成 /etc/V2bX/config.json
function update_v2bx_config() {
    echo -e "${GREEN}请输入 NodeID:${NC}"
    read node_id

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
            "CertDomain": "0.yunduanconnect.com",
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
    cp /etc/V2bX/sing_origin.json /etc/V2bX/sing_origin.json.bak

    private_key=$(grep '^PrivateKey' /etc/wireguard/warp.conf | awk -F '= ' '{print $2}')
    reserved=$(grep '^#Reserved' /etc/wireguard/warp.conf | awk -F '= ' '{print $2}' | tr -d '[]')

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
          "disney",
          "instagram",
          "netflix"
        ],
        "outbound": "warp"
      },
      {
        "domain_keyword": [
          "hongkongtrader",
          "yd-zl",
          "云端智联",
          "yunduanzhilian",
          "yunduanconnect"
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

    echo -e "${GREEN}Singbox 配置文件生成成功！${NC}"
}

# 下载证书和密钥
function download_certificates() {
    echo -e "${GREEN}正在下载证书和密钥...${NC}"
    
    wget -O /etc/V2bX/fullchain.cer https://raw.githubusercontent.com/CraftedInCode/tools/main/sh/node/fullchain.cer
    wget -O /etc/V2bX/cert.key https://raw.githubusercontent.com/CraftedInCode/tools/main/sh/node/cert.key

    if [ $? -ne 0 ]; then
        echo -e "${GREEN}下载证书和密钥失败！${NC}"
        exit 1
    fi

    echo -e "${GREEN}证书和密钥下载成功！${NC}"
}

# 重启 V2bX 服务
function restart_v2bx() {
    echo -e "${GREEN}正在重启 V2bX 服务...${NC}"
    V2bX restart
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}V2bX 服务重启成功！${NC}"
    else
        echo -e "${GREEN}V2bX 服务重启失败！${NC}"
    fi
}

# 执行脚本的主要流程
Debian_update
install_v2bx
update_v2bx_config
generate_sing_origin_json
download_certificates
restart_v2bx

echo -e "${GREEN}所有操作已完成！${NC}"
