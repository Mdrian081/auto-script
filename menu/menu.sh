#!/bin/bash

get_ram_info() {
    ram_info=$(free -m | awk 'NR==2{print $2,$3}')
    tram=$(echo "$ram_info" | awk '{print $1}')
    uram=$(echo "$ram_info" | awk '{print $2}')
}

get_cpu_usage() {
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    cpu_usage=$(echo "$cpu_usage" | awk '{printf "%.2f", $1}')
    cpu_usage+=" %"
}

show_vps_info() {
    clear
    domain=$(cat /etc/xray/domain 2>/dev/null || echo "Not set")
    uptime=$(uptime -p | cut -d " " -f 2-10)
    DATE2=$(date -R | cut -d " " -f -5)
    IPVPS=$(curl -s ifconfig.me 2>/dev/null || wget -qO- ifconfig.me)
    LOC=$(curl -sS "https://api.country.is/${IPVPS}" 2>/dev/null | jq -r '.country' 2>/dev/null || echo "BD")

    # Load bug host
    [ -f /var/lib/bug.conf ] && source /var/lib/bug.conf
    BUG_HOST="${BUG_HOST:-bug.com}"

    echo -e "\e[1;33m -------------------------------------------------\e[0m"
    echo -e "\e[1;34m              Riyan VPS VPN Panel                \e[0m"
    echo -e "\e[1;33m -------------------------------------------------\e[0m"
    echo -e "\e[1;32m OS            \e[0m: $(hostnamectl | grep "Operating System" | cut -d ' ' -f5-)"
    echo -e "\e[1;32m Uptime        \e[0m: $uptime"
    echo -e "\e[1;32m Public IP     \e[0m: $IPVPS"
    echo -e "\e[1;32m Country       \e[0m: $LOC"
    echo -e "\e[1;32m DOMAIN        \e[0m: $domain"
    echo -e "\e[1;32m BUG HOST      \e[0m: $BUG_HOST"
    echo -e "\e[1;32m DATE & TIME   \e[0m: $DATE2"
    echo -e "\e[1;33m -------------------------------------------------\e[0m"
}

show_cpu_ram_info() {
    get_ram_info
    get_cpu_usage
    echo -e "\e[1;34m                Riyan CPU/RAM INFO               \e[0m"
    echo -e "\e[1;33m -------------------------------------------------\e[0m"
    echo -e "\e[1;32m CPU USAGE   \e[0m: $cpu_usage"
    echo -e "\e[1;32m RAM USED    \e[0m: ${uram} MB"
    echo -e "\e[1;32m RAM TOTAL   \e[0m: ${tram} MB"
    echo -e "\e[1;33m -------------------------------------------------\e[0m"
}

show_menu() {
    clear
    show_vps_info
    show_cpu_ram_info

    echo -e "\e[1;34m                   Riyan MENU                    \e[0m"
    echo -e "\e[1;33m -------------------------------------------------\e[0m"
    echo -e ""
    echo -e "\e[1;36m 1 \e[0m: Menu SSH"
    echo -e "\e[1;36m 2 \e[0m: Menu Vmess"
    echo -e "\e[1;36m 3 \e[0m: Menu Vless"
    echo -e "\e[1;36m 4 \e[0m: Menu Trojan"
    echo -e "\e[1;36m 5 \e[0m: Menu Shadowsocks"
    echo -e "\e[1;36m 6 \e[0m: Menu Setting"
    echo -e "\e[1;36m 7 \e[0m: Status Service"
    echo -e "\e[1;36m 8 \e[0m: Clear RAM Cache"
    echo -e "\e[1;36m 9 \e[0m: Reboot VPS"
    echo -e "\e[1;36m t \e[0m: Telegram Bot 🤖"
    echo -e "\e[1;36m x \e[0m: Exit Script"
    echo -e ""
    echo -e "\e[1;33m -------------------------------------------------\e[0m"
    echo -e "\e[1;32m Script By  \e[0m: Riyan"
    echo -e "\e[1;32m Telegram   \e[0m: https://t.me/RiyanFF"
    echo -e "\e[1;33m -------------------------------------------------\e[0m"
    echo -e ""
    read -p " Select menu :  " opt
    echo ""
    case $opt in
    1) clear ; m-sshovpn ;;
    2) clear ; m-vmess ;;
    3) clear ; m-vless ;;
    4) clear ; m-trojan ;;
    5) clear ; m-ssws ;;
    6) clear ; m-system ;;
    7) clear ; running ;;
    8) clear ; clearcache ;;
    9) clear ; /sbin/reboot ;;
t) clear ; riyanbot &&  echo "Bot started in background" ;;
    t) clear ; xolpanel ;;
    x) exit ;;
    *) echo "Invalid selection" ; sleep 1 ;;
    esac
}

domain=$(cat /etc/xray/domain 2>/dev/null || echo "Not set")

while true; do
    show_menu
done
