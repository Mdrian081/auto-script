#!/bin/bash
clear
echo -e "\e[1;33m[*] Restarting all services...\e[0m"
systemctl restart xray nginx ssh badvpn ssh-ws dropbear 2>/dev/null
echo -e "\e[1;32m[✓] All services restarted!\e[0m"
sleep 2
menu
