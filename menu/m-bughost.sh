#!/bin/bash

set_bug_host() {
    local sim=$1
    local bug=$2
    
    # /var/lib/bug.conf এ save করি
    echo "BUG_HOST=\"$bug\"" > /var/lib/bug.conf
    echo "SIM_TYPE=\"$sim\"" >> /var/lib/bug.conf
    
    # nginx config এ bug host update করি
    if [ -f /etc/nginx/conf.d/xray.conf ]; then
        sed -i "s/server_name .*/server_name $bug $bug.haki9163.duckdns.org *.$(cat /etc/xray/domain);/" /etc/nginx/conf.d/xray.conf 2>/dev/null || true
    fi
    
    echo -e "\e[32m[✓] Bug host set to: $bug\e[0m"
    echo -e "\e[32m[✓] SIM type: $sim\e[0m"
    systemctl restart nginx xray > /dev/null 2>&1
    sleep 1
}

clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m       • SIM Bug Host Settings •       \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
echo -e " [\e[36m•1\e[0m] Grameenphone (GP)"
echo -e " [\e[36m•2\e[0m] Robi / Airtel"
echo -e " [\e[36m•3\e[0m] Banglalink (BL)"
echo -e " [\e[36m•4\e[0m] Teletalk"
echo -e " [\e[36m•5\e[0m] Custom Bug Host"
echo -e ""
echo -e " [\e[31m•0\e[0m] \e[31mBACK TO MENU\033[0m"
echo -e ""
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
read -p " Select SIM : " opt

case $opt in
1)
    clear
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;100;33m         Grameenphone Bug Host          \E[0m"
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e ""
    echo -e " [1] speedtest.net"
    echo -e " [2] gtv.com.bd"
    echo -e " [3] gp.com.bd"
    echo -e " [4] Custom"
    echo -e ""
    read -p " Select : " gp_opt
    case $gp_opt in
        1) set_bug_host "Grameenphone" "speedtest.net" ;;
        2) set_bug_host "Grameenphone" "gtv.com.bd" ;;
        3) set_bug_host "Grameenphone" "gp.com.bd" ;;
        4) read -p " Enter custom bug: " custom_bug ; set_bug_host "Grameenphone" "$custom_bug" ;;
    esac
    ;;
2)
    clear
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;100;33m           Robi / Airtel Bug Host          \E[0m"
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e ""
    echo -e " [1] robicorporate.com"
    echo -e " [2] robi.com.bd"
    echo -e " [3] airtel.com.bd"
    echo -e " [4] Custom"
    echo -e ""
    read -p " Select : " robi_opt
    case $robi_opt in
        1) set_bug_host "Robi" "robicorporate.com" ;;
        2) set_bug_host "Robi" "robi.com.bd" ;;
        3) set_bug_host "Robi" "airtel.com.bd" ;;
        4) read -p " Enter custom bug: " custom_bug ; set_bug_host "Robi" "$custom_bug" ;;
    esac
    ;;
3)
    clear
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;100;33m          Banglalink Bug Host           \E[0m"
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e ""
    echo -e " [1] bli.com.bd"
    echo -e " [2] banglalink.net"
    echo -e " [3] Custom"
    echo -e ""
    read -p " Select : " bl_opt
    case $bl_opt in
        1) set_bug_host "Banglalink" "bli.com.bd" ;;
        2) set_bug_host "Banglalink" "banglalink.net" ;;
        3) read -p " Enter custom bug: " custom_bug ; set_bug_host "Banglalink" "$custom_bug" ;;
    esac
    ;;
4)
    clear
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;100;33m           Teletalk Bug Host            \E[0m"
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e ""
    echo -e " [1] teletalk.com.bd"
    echo -e " [2] Custom"
    echo -e ""
    read -p " Select : " tt_opt
    case $tt_opt in
        1) set_bug_host "Teletalk" "teletalk.com.bd" ;;
        2) read -p " Enter custom bug: " custom_bug ; set_bug_host "Teletalk" "$custom_bug" ;;
    esac
    ;;
5)
    read -p " Enter SIM name: " sim_name
    read -p " Enter bug host: " custom_bug
    set_bug_host "$sim_name" "$custom_bug"
    ;;
0) menu ; exit ;;
*) m-bughost ;;
esac

echo -e ""
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " Current Bug Host Settings:"
if [ -f /var/lib/bug.conf ]; then
    source /var/lib/bug.conf
    echo -e " SIM    : \e[36m$SIM_TYPE\e[0m"
    echo -e " Bug    : \e[36m$BUG_HOST\e[0m"
fi
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
read -n 1 -s -r -p "Press any key to back on menu"
m-system
