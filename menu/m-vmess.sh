#!/bin/bash
MYIP=$(wget -qO- ipv4.icanhazip.com);
echo "Checking VPS"
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m       • Riyan VMESS MENU •         \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
echo -e " [\e[36m•1\e[0m] Create Account Vmess "
echo -e " [\e[36m•2\e[0m] Trial Account Vmess "
echo -e " [\e[36m•3\e[0m] Extending Account Vmess "
echo -e " [\e[36m•4\e[0m] Delete Account Vmess "
echo -e " [\e[36m•5\e[0m] Check User Login Vmess "
echo -e " [\e[36m•6\e[0m] User list created Account "
echo -e ""
echo -e " [\e[31m•0\e[0m] \e[31mBACK TO Riyan MENU\033[0m"
echo -e ""
echo -e   "Press x or [ Ctrl+C ] • To-Exit"
echo ""
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
read -p " Select menu :  "  opt
echo -e ""
case $opt in
1) clear ; add-ws ; exit ;;
2) clear ; trialvmess ; exit ;;
3) clear ; renew-ws ; exit ;;
4) clear ; del-ws ; exit ;;
5) clear ; cek-ws ; exit ;;
6) clear ; cat /etc/log-create-vmess.log ; exit ;;
0) clear ; menu ; exit ;;
x) exit ;;
*) echo " wrong option " ; sleep 1 ; m-sshovpn ;;
esac
