#!/bin/bash
clear
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;33m         Service Status               \e[0m"
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
for svc in xray nginx ssh dropbear badvpn ssh-ws riyanbot; do
    status=$(systemctl is-active $svc 2>/dev/null)
    if [ "$status" = "active" ]; then
        echo -e "\e[1;32m ✅ $svc: running\e[0m"
    else
        echo -e "\e[1;31m ❌ $svc: stopped\e[0m"
    fi
done
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
