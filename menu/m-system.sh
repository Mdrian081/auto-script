#!/bin/bash
MYIP=$(wget -qO- ipv4.icanhazip.com);
echo "Checking VPS"
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m          • Riyan SYSTEM MENU •          \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
echo -e " [\e[36m•1\e[0m] Panel Domain"
echo -e " [\e[36m•2\e[0m] Speedtest VPS"
echo -e " [\e[36m•3\e[0m] Set Auto Reboot"
echo -e " [\e[36m•4\e[0m] Restart All Service"
echo -e " [\e[36m•5\e[0m] Check Bandwith"
echo -e " [\e[36m•6\e[0m] Install TCP BBR"
echo -e " [\e[36m•7\e[0m] DNS CHANGER"
echo -e " [\e[36m•8\e[0m] SIM Bug Host Settings 🇧🇩"
echo -e ""
echo -e " [\e[31m•0\e[0m] \e[31mBACK TO Riyan MENU\033[0m"
echo -e ""
echo -e "Press x or [ Ctrl+C ] • To-Exit"
echo -e ""
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
read -p " Select menu : " opt
echo -e ""
case $opt in
1) clear ; m-domain ; exit ;;
2) clear ; speedtest ; exit ;;
3) clear ; auto-reboot ; exit ;;
4) clear ; restart ; exit ;;
5) clear ; bw ; exit ;;
6) clear ; m-tcp ; exit ;;
7) clear ; m-dns ; exit ;;
8) clear ; m-bughost ; exit ;;
0) clear ; menu ; exit ;;
x) exit ;;
*) echo -e "" ; echo "wrong options" ; sleep 1 ; m-system ;;
esac
