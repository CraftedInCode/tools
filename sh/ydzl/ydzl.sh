#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # 无色

# 主菜单
function show_menu() {
    clear
    echo "==============================="
    echo "         云端智联 保障         "
    echo "==============================="
    echo -e "${RED}1.${NC}  安装V2bX"
    echo -e "${RED}2.${NC}  修改DNS为CF"
    echo -e "${RED}3.${NC}  检测IP优先级"
    echo -e "${RED}4.${NC}  一键部署节点"
    echo -e "${RED}5.${NC}  升级Debian软件包"
    echo -e "${RED}6.${NC}  开启BBR"
    echo -e "${RED}7.${NC}  检测IP质量"
    echo -e "${RED}8.${NC}  安装EasyGost"
    echo -e "${RED}9.${NC}  开放所有端口"
    echo -e "${RED}10.${NC} ChatGPT检测"
    echo -e "${RED}11.${NC} 添加WARP网络"
    echo -e "${RED}12.${NC} IPv4优先"
    echo -e "${RED}13.${NC} IPv6优先"
    echo -e "${RED}14.${NC} Linux测速"
    echo -e "${RED}15.${NC} 增减SWAP"
    echo -e "${RED}16.${NC} 安装3x-ui"
    echo -e "${RED}17.${NC} Linux测速"
    echo "==============================="
    read -p "请输入选项编号: " option
    case $option in
        1) run_v2bx ;;
        2) update_dns ;;
        3) test_ip ;;
        4) one_node ;;
        5) Debian_update ;;
        6) bbr ;;
        7) IPQuality ;;
        8) easygost ;;
        9) open_ports ;;
        10) chatgpt_menu ;;
        11) warp ;;
        12) ipv4 ;;
        13) ipv6 ;;
        14) Speedtest ;;
        15) swap ;;
        16) 3x-ui ;;
        *) echo "无效选项，请重试." && sleep 2 && show_menu ;;
    esac
}

# 1. 运行 V2bX
function run_v2bx() {
    echo -e "${GREEN}正在运行 V2bX...${NC}"
    wget -N https://raw.githubusercontent.com/wyx2685/V2bX-script/master/install.sh && bash install.sh
    sleep 2
    show_menu
}

# 2. 修改 DNS 为 Cloudflare
function update_dns() {
    echo -e "${GREEN}正在修改 DNS 为 Cloudflare...${NC}"
    if [ "$(id -u)" -ne "0" ]; then
        echo -e "${RED}请以 root 权限运行此脚本${NC}"
        sleep 2
        show_menu
    else
        echo -e "# 更新 /etc/resolv.conf" > /etc/resolv.conf
        echo -e "nameserver 1.1.1.1" >> /etc/resolv.conf
        echo -e "nameserver 1.0.0.1" >> /etc/resolv.conf
        echo -e "nameserver 2606:4700:4700::1111" >> /etc/resolv.conf
        echo -e "nameserver 2606:4700:4700::1001" >> /etc/resolv.conf
        echo -e "# 更新 /etc/systemd/resolved.conf" > /etc/systemd/resolved.conf
        echo -e "[Resolve]" >> /etc/systemd/resolved.conf
        echo -e "DNS=1.1.1.1 1.0.0.1" >> /etc/systemd/resolved.conf
        echo -e "FallbackDNS=2606:4700:4700::1111 2606:4700:4700::1001" >> /etc/systemd/resolved.conf
        systemctl enable systemd-resolved
        systemctl restart systemd-resolved
        echo -e "${GREEN}DNS 设置已更新为 Cloudflare 公共 DNS。${NC}"
        echo -e "IPv4 DNS: 1.1.1.1, 1.0.0.1"
        echo -e "IPv6 DNS: 2606:4700:4700::1111, 2606:4700:4700::1001"
    fi
    sleep 2
    show_menu
}


# 3. 检测 IP 优先级
function test_ip() {
    echo -e "${GREEN}正在检测 IP 优先级...${NC}"
    curl ip.sb
    sleep 2
    show_menu
}

# 4. 一键安装节点
function one_node() {
    echo -e "${GREEN}全自动部署V2bX节点...${NC}"
    wget -O /root/ydzl_node.sh "https://raw.githubusercontent.com/CraftedInCode/tools/main/sh/node/ydzl_node.sh"
    chmod +x /root/ydzl_node.sh
    bash /root/ydzl_node.sh
    sleep 2
    show_menu
}


# 5. Debian 升级软件包
function Debian_update() {
    echo -e "${GREEN}正在更新 Debian 软件包...${NC}"
    echo -e "${GREEN}正在更新软件包列表...${NC}"
    sudo apt update
    echo -e "${GREEN}正在升级所有已安装的软件包...${NC}"
    sudo apt upgrade -y
    echo -e "${GREEN}正在进行全面升级...${NC}"
    sudo apt full-upgrade -y
    echo -e "${GREEN}正在清理不再需要的包...${NC}"
    sudo apt autoremove -y
    echo -e "${GREEN}软件包更新完成！${NC}"
    sleep 2
    show_menu
}

# 6. 开启 BBR
function bbr() {
    echo -e "${GREEN}正在开启 BBR...${NC}"
    apt-get install ca-certificates wget -y
    update-ca-certificates
    wget -O tcpx.sh "https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh"
    chmod +x tcpx.sh
    ./tcpx.sh
    sleep 2
    show_menu
}

# 7. 检测 IP 质量
function IPQuality() {
    echo -e "${GREEN}正在检测 IP 质量...${NC}"
    bash <(curl -Ls IP.Check.Place)
    sleep 2
    show_menu
}

# 8. 安装 EasyGost
function easygost() {
    echo -e "${GREEN}正在安装 EasyGost...${NC}"
    wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/KANIKIG/Multi-EasyGost/master/gost.sh
    chmod +x gost.sh
    ./gost.sh
    sleep 2
    show_menu
}

# 9. 开放所有端口
function open_ports() {
    echo -e "${GREEN}正在开放所有防火墙端口...${NC}"
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
    echo -e "${GREEN}防火墙端口已成功开放！${NC}"
    sleep 2
    show_menu
}

# 10. 检测 ChatGPT 使用情况
function chatgpt_menu() {
    echo -e "${GREEN}正在检测 ChatGPT 使用情况...${NC}"
    chatgpt "https://api.openai.com/" "error" "Web"
    chatgpt "https://ios.chat.openai.com/" "VPN" "iOS"
    chatgpt "https://android.chat.openai.com/" "VPN" "Android"
    sleep 2
    show_menu
}
# 实现 ChatGPT 检测的辅助函数
function chatgpt() {
    url=$1
    keyword=$2
    type=$3

    # 发送请求并获取页面内容
    response=$(curl -s "$url")

    # 检查页面内容是否包含关键字
    if echo "$response" | grep -q "$keyword"; then
        printf "\r %-20s:\t${RED}No${NC}\n" "${type}_ChatGPT"
    else
        printf "\r %-20s:\t${GREEN}Yes${NC}\n" "${type}_ChatGPT"
    fi
}

#11. 安装/管理 WARP
function warp() {
    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh
    sleep 2
    show_menu
}

#12. IPv4优先
function ipv4() {
    sed -i 's/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf
    sleep 2
    show_menu
}

#13. IPv6优先
function ipv6() {
    sed -i 's/precedence ::ffff:0:0\/96  100/#precedence ::ffff:0:0\/96  100/' /etc/gai.conf
    sleep 2
    show_menu
}

#14. Speedtest
function Speedtest() {
    bash <(curl -sL https://raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
    sleep 2
    show_menu
}

#15. swap
function swap() {
    echo "请选择操作:"
    echo "1. 添加交换内存"
    echo "2. 删除现有交换内存"
    read -p "请输入选项 [1-2]: " option

    case $option in
        1)
            # 添加交换内存
            read -p "请输入你想要添加的交换内存大小（单位为MB，例如1024）: " swap_size
            if ! [[ "$swap_size" =~ ^[0-9]+$ ]]; then
                echo "请输入有效的数字."
                sleep 2
                show_menu
                return
            fi
            swap_file="/swapfile"
            fallocate -l "${swap_size}M" $swap_file
            chmod 600 $swap_file
            mkswap $swap_file
            swapon $swap_file
            echo "$swap_file none swap sw 0 0" | tee -a /etc/fstab
            echo "成功添加了 ${swap_size}MB 的交换内存."
            ;;
        2)
            # 删除现有交换内存
            swap_file="/swapfile"
            swapoff $swap_file
            rm -f $swap_file
            sed -i '/\/swapfile/d' /etc/fstab
            echo "成功删除了交换内存."
            ;;
        *)
            echo "无效的选项."
            ;;
    esac

    sleep 2
    show_menu
}


#14. 3x-ui
function 3x-ui() {
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    sleep 2
    show_menu
}
# 启动菜单
show_menu
