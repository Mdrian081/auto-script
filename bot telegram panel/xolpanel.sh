#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}       Riyan VPS - Telegram Bot        ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""

# Check if already installed
if [ -d "/root/xolpanel" ]; then
    echo -e "${GREEN}[✓] Bot already installed${NC}"
    echo -e ""
    echo -e " [1] Start Bot"
    echo -e " [2] Stop Bot"
    echo -e " [3] Restart Bot"
    echo -e " [4] Bot Status"
    echo -e " [5] Reinstall Bot"
    echo -e " [0] Back to Menu"
    echo -e ""
    read -p " Select : " botopt
    case $botopt in
        1)
            cd /root/xolpanel
            screen -dmS xolbot python3 bot.py
            echo -e "${GREEN}[✓] Bot Started!${NC}"
            ;;
        2)
            screen -S xolbot -X quit 2>/dev/null
            echo -e "${YELLOW}[!] Bot Stopped${NC}"
            ;;
        3)
            screen -S xolbot -X quit 2>/dev/null
            sleep 2
            cd /root/xolpanel
            screen -dmS xolbot python3 bot.py
            echo -e "${GREEN}[✓] Bot Restarted!${NC}"
            ;;
        4)
            if screen -list | grep -q "xolbot"; then
                echo -e "${GREEN}[✓] Bot is RUNNING${NC}"
            else
                echo -e "${RED}[✗] Bot is STOPPED${NC}"
            fi
            ;;
        5)
            rm -rf /root/xolpanel
            bash /usr/bin/xolpanel
            exit
            ;;
        0) menu ; exit ;;
    esac
    echo -e ""
    read -n 1 -s -r -p "Press any key to continue"
    xolpanel
    exit
fi

# Fresh install
echo -e "${YELLOW}[*] Installing dependencies...${NC}"
apt update -y > /dev/null 2>&1
apt install -y python3 python3-pip git screen unzip > /dev/null 2>&1

echo -e "${YELLOW}[*] Cloning bot panel...${NC}"
cd /root
git clone https://github.com/givpn/xolpanel.git

if [ ! -d "/root/xolpanel" ]; then
    echo -e "${RED}[✗] Clone failed! Check internet connection${NC}"
    exit 1
fi

# unzip if needed
if [ -f "/root/xolpanel/xolpanel.zip" ]; then
    unzip -o /root/xolpanel/xolpanel.zip -d /root/xolpanel/ > /dev/null 2>&1
fi

echo -e "${YELLOW}[*] Installing Python requirements...${NC}"
pip3 install -r /root/xolpanel/requirements.txt --quiet 2>/dev/null
pip3 install pillow --quiet 2>/dev/null

echo -e ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}        Enter Bot Configuration        ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
read -e -p " [*] Bot Token    : " bottoken
read -e -p " [*] Telegram ID  : " admin
domain=$(cat /etc/xray/domain 2>/dev/null || echo "")
if [ -z "$domain" ]; then
    read -e -p " [*] Your Domain  : " domain
else
    echo -e " [*] Domain       : ${GREEN}$domain${NC} (auto detected)"
fi

# Save config
cat > /root/xolpanel/var.txt << EOF
BOT_TOKEN="$bottoken"
ADMIN="$admin"
DOMAIN="$domain"
EOF

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[✓] Bot Configured Successfully!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
echo -e " Bot Token  : $bottoken"
echo -e " Telegram ID: $admin"
echo -e " Domain     : $domain"
echo -e ""

# Start bot with screen (keeps running after SSH close)
cd /root/xolpanel
screen -dmS xolbot python3 bot.py

echo -e "${GREEN}[✓] Bot Started in background!${NC}"
echo -e "${YELLOW}[*] Bot will keep running even after SSH close${NC}"
echo -e ""
echo -e " To check bot: ${CYAN}screen -r xolbot${NC}"
echo -e " To stop bot : ${CYAN}screen -S xolbot -X quit${NC}"
echo -e ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e " Script By Riyan | t.me/RiyanFF"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
