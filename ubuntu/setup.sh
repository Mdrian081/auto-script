#!/bin/bash

# Ensure root
if [ "${EUID}" -ne 0 ]; then
    echo "You need to run this script as root"
    sleep 5; exit 1
fi

# Check OS version
OS=$(lsb_release -si 2>/dev/null || cat /etc/os-release | grep ^ID= | cut -d= -f2)
VER=$(lsb_release -sr 2>/dev/null || cat /etc/os-release | grep ^VERSION_ID= | cut -d= -f2 | tr -d '")
echo -e "\e[1;33m[*] OS Detected: $OS $VER\e[0m"

# Supported OS check
if [[ "$OS" != "ubuntu" ]] && [[ "$OS" != "Ubuntu" ]] && [[ "$OS" != "debian" ]] && [[ "$OS" != "Debian" ]]; then
    echo -e "\e[1;31m[✗] Unsupported OS! Use Ubuntu 20/22/24 or Debian 10/11/12\e[0m"
    exit 1
fi

echo -e "\e[1;32m[✓] OS Supported!\e[0m"

# Check virtualization
if [ "$(systemd-detect-virt)" == "openvz" ]; then
    echo "OpenVZ is not supported"
    sleep 5; exit 1
fi

clear
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;33m     Riyan VPS VPN - Auto Install     \e[0m"
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

# Create directories
mkdir -p /etc/xray /etc/v2ray /var/lib
touch /etc/xray/domain /etc/v2ray/domain /etc/xray/scdomain /etc/v2ray/scdomain
echo "" > /var/lib/ipvps.conf
echo "" > /var/lib/bug.conf

# Update & install packages
apt-get update
apt-get install -y curl wget unzip screen nginx python3 python3-pip \
    certbot git dos2unix jq openssl dropbear stunnel4 \
    software-properties-common build-essential

# Python 3 packages
pip3 install aiogram requests --quiet 2>/dev/null

# SSH Keepalive fix
grep -q "ClientAliveInterval" /etc/ssh/sshd_config || echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
grep -q "ClientAliveCountMax" /etc/ssh/sshd_config || echo "ClientAliveCountMax 10" >> /etc/ssh/sshd_config
grep -q "TCPKeepAlive" /etc/ssh/sshd_config || echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config
systemctl restart ssh

# Dropbear port 143
sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear 2>/dev/null || true
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/' /etc/default/dropbear 2>/dev/null || true
systemctl restart dropbear 2>/dev/null || true

# Domain config
echo ""
echo -e "\e[1;33m1. Use DuckDNS Domain (Recommended)\e[0m"
echo -e "\e[1;33m2. Enter Your Own Domain\e[0m"
echo ""
read -rp "Input 1 or 2: " dns

if [ "$dns" -eq 1 ]; then
    echo ""
    read -rp "Enter your DuckDNS subdomain (e.g. mysite): " subdomain
    domain="${subdomain}.duckdns.org"
    echo "Enter your DuckDNS token:"
    read -rp "Token: " ducktoken
    curl -s "https://www.duckdns.org/update?domains=${subdomain}&token=${ducktoken}&ip=" > /dev/null
    echo -e "\e[1;32m[✓] Domain set: ${domain}\e[0m"
else
    read -rp "Enter your domain: " domain
fi

echo "$domain" > /etc/xray/domain
echo "$domain" > /etc/v2ray/domain
echo "DOMAIN=\"$domain\"" > /var/lib/ipvps.conf

# SSL Certificate
echo -e "\e[1;33m[*] Getting SSL certificate...\e[0m"
systemctl stop nginx 2>/dev/null
certbot certonly --standalone --preferred-challenges http \
    -d "$domain" --non-interactive --agree-tos \
    -m "admin@${domain}" 2>/dev/null || \
certbot certonly --standalone --preferred-challenges http \
    -d "$domain" --non-interactive --agree-tos \
    -m "mdrian081@gmail.com"

# Copy certs
if [ -f "/etc/letsencrypt/live/${domain}/fullchain.pem" ]; then
    cp /etc/letsencrypt/live/${domain}/fullchain.pem /etc/xray/xray.crt
    cp /etc/letsencrypt/live/${domain}/privkey.pem /etc/xray/xray.key
    echo -e "\e[1;32m[✓] SSL Certificate installed!\e[0m"
else
    echo -e "\e[1;31m[✗] SSL failed - using self-signed\e[0m"
    openssl req -x509 -newkey rsa:4096 -keyout /etc/xray/xray.key \
        -out /etc/xray/xray.crt -days 365 -nodes \
        -subj "/CN=${domain}" 2>/dev/null
fi

# Install Xray
echo -e "\e[1;33m[*] Installing Xray...\e[0m"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Xray config
cat > /usr/local/etc/xray/config.json << XEOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {
      "port": 14016, "listen": "127.0.0.1", "protocol": "vless",
      "settings": {"clients": [], "decryption": "none"},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/vless"}},
      "tag": "vless-ws"
    },
    {
      "port": 24456, "listen": "127.0.0.1", "protocol": "vless",
      "settings": {"clients": [], "decryption": "none"},
      "streamSettings": {"network": "grpc", "grpcSettings": {"serviceName": "vless-grpc"}},
      "tag": "vless-grpc"
    },
    {
      "port": 23456, "listen": "127.0.0.1", "protocol": "vmess",
      "settings": {"clients": []},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/vmess"}},
      "tag": "vmess-ws"
    },
    {
      "port": 31234, "listen": "127.0.0.1", "protocol": "vmess",
      "settings": {"clients": []},
      "streamSettings": {"network": "grpc", "grpcSettings": {"serviceName": "vmess-grpc"}},
      "tag": "vmess-grpc"
    },
    {
      "port": 25432, "listen": "127.0.0.1", "protocol": "trojan",
      "settings": {"clients": []},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/trojan-ws"}},
      "tag": "trojan-ws"
    },
    {
      "port": 33456, "listen": "127.0.0.1", "protocol": "trojan",
      "settings": {"clients": []},
      "streamSettings": {"network": "grpc", "grpcSettings": {"serviceName": "trojan-grpc"}},
      "tag": "trojan-grpc"
    },
    {
      "port": 30300, "listen": "127.0.0.1", "protocol": "shadowsocks",
      "settings": {
        "clients": [{"password": "riyan@123", "method": "chacha20-ietf-poly1305", "email": "default"}],
        "network": "tcp,udp"
      },
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/ss-ws"}},
      "tag": "ss-ws"
    }
  ],
  "outbounds": [
    {"protocol": "freedom", "settings": {}, "tag": "direct"},
    {"protocol": "blackhole", "settings": {}, "tag": "block"}
  ],
  "routing": {
    "rules": [{"type": "field", "ip": ["geoip:private"], "outboundTag": "block"}]
  }
}
XEOF
cp /usr/local/etc/xray/config.json /etc/xray/config.json

# Nginx config
cat > /etc/nginx/conf.d/xray.conf << NEOF
server {
    listen 80;
    server_name ${domain};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${domain} *.${domain};
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;

    location = /vless {
        proxy_pass http://127.0.0.1:14016;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    location = /vmess {
        proxy_pass http://127.0.0.1:23456;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    location = /trojan-ws {
        proxy_pass http://127.0.0.1:25432;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    location = /ss-ws {
        proxy_pass http://127.0.0.1:30300;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
    location ^~ /vless-grpc {
        grpc_pass grpc://127.0.0.1:24456;
        grpc_set_header X-Real-IP \$remote_addr;
    }
    location ^~ /vmess-grpc {
        grpc_pass grpc://127.0.0.1:31234;
        grpc_set_header X-Real-IP \$remote_addr;
    }
    location ^~ /trojan-grpc {
        grpc_pass grpc://127.0.0.1:33456;
        grpc_set_header X-Real-IP \$remote_addr;
    }
    location / {
        proxy_pass http://127.0.0.1:2082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
}
NEOF

# SSH WebSocket (port 2082)
cat > /usr/bin/ssh-ws << 'SWEOF'
#!/usr/bin/python3
import socket, threading, select

LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = 2082
BUFLEN = 4096 * 4
TIMEOUT = 60
MSG = 'HTTP/1.1 101 Switching Protocol\r\n\r\n'

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port

    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.running = True
        try:
            self.soc.bind((self.host, self.port))
            self.soc.listen(0)
        except Exception as e:
            return
        while self.running:
            try:
                c, addr = self.soc.accept()
                c.setblocking(1)
            except Exception as e:
                break
            conn = ConnectionHandler(c, self, addr)
            conn.start()

    def close(self):
        try:
            self.running = False
            self.soc.close()
        except:
            pass

class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.server = server

    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except:
            pass
        finally:
            self.clientClosed = True
        try:
            if not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except:
            pass
        finally:
            self.targetClosed = True

    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN).decode('utf-8')
            hostPort = self.findHeader(self.client_buffer, 'X-Real-Host')
            if hostPort == '':
                hostPort = 'localhost:22'
            self.method_CONNECT(hostPort)
        except Exception as e:
            pass
        finally:
            self.close()

    def findHeader(self, head, header):
        aux = head.find(header + ': ')
        if aux == -1:
            return ''
        aux = head.find(':', aux)
        head = head[aux+2:]
        aux = head.find('\r\n')
        if aux == -1:
            return ''
        return head[:aux]

    def method_CONNECT(self, path):
        self.target = self.connectTarget(path)
        self.client.send(MSG.encode())
        self.client_buffer = ''
        self.transferData(self.client, self.target)

    def connectTarget(self, host):
        i = host.find(':')
        if i != -1:
            port = int(host[i+1:])
            host = host[:i]
        else:
            port = 22
        soc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        soc.connect((host, port))
        self.targetClosed = False
        return soc

    def transferData(self, client, target):
        socs = [client, target]
        while True:
            recv, _, err = select.select(socs, [], socs, TIMEOUT)
            if err:
                break
            if recv:
                for in_ in recv:
                    try:
                        data = in_.recv(BUFLEN)
                        if data:
                            if in_ is target:
                                client.send(data)
                            else:
                                while data:
                                    byte = target.send(data)
                                    data = data[byte:]
                        else:
                            break
                    except:
                        break

def main():
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()
    try:
        while True:
            pass
    except KeyboardInterrupt:
        server.close()

if __name__ == '__main__':
    main()
SWEOF
chmod +x /usr/bin/ssh-ws

# SSH-WS service
cat > /etc/systemd/system/ssh-ws.service << SEOF
[Unit]
Description=SSH WebSocket
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/bin/ssh-ws
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SEOF

# BadVPN
wget -q -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64"
chmod +x /usr/bin/badvpn-udpgw
cat > /etc/systemd/system/badvpn.service << BEOF
[Unit]
Description=BadVPN UDP Gateway
After=network.target

[Service]
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
Restart=always

[Install]
WantedBy=multi-user.target
BEOF

# Install menu scripts
wget -q -O /usr/bin/menu https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/menu/menu.sh
wget -q -O /usr/bin/m-vless https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/menu/m-vless.sh
wget -q -O /usr/bin/m-vmess https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/menu/m-vmess.sh
wget -q -O /usr/bin/m-trojan https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/menu/m-trojan.sh
wget -q -O /usr/bin/m-sshovpn https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/menu/m-sshovpn.sh
wget -q -O /usr/bin/m-ssws https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/menu/m-ssws.sh
wget -q -O /usr/bin/m-system https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/menu/m-system.sh
wget -q -O /usr/bin/m-bughost https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/menu/m-bughost.sh
wget -q -O /usr/bin/add-vless https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/xray/add-vless.sh
wget -q -O /usr/bin/add-ws https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/xray/add-ws.sh
wget -q -O /usr/bin/add-tr https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/xray/add-tr.sh
wget -q -O /usr/bin/del-vless https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/xray/del-vless.sh
wget -q -O /usr/bin/del-tr https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/xray/del-tr.sh
wget -q -O /usr/bin/del-ws https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/xray/del-ws.sh
wget -q -O /usr/bin/renew-vless https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/xray/renew-vless.sh
wget -q -O /usr/bin/renew-tr https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/xray/renew-tr.sh
wget -q -O /usr/bin/running https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/menu/running.sh
wget -q -O /usr/bin/restart https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/menu/restart.sh
wget -q -O /usr/bin/clearcache https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/menu/clearcache.sh
wget -q -O /usr/bin/xolpanel "https://raw.githubusercontent.com/Mdrian081/Vps_vpn/main/bot%20telegram%20panel/xolpanel.sh"

# Make executable
chmod +x /usr/bin/menu /usr/bin/m-* /usr/bin/add-* /usr/bin/del-* \
         /usr/bin/renew-* /usr/bin/running /usr/bin/restart \
         /usr/bin/clearcache /usr/bin/xolpanel 2>/dev/null

# dos2unix all scripts
find /usr/bin -name "*.sh" -exec dos2unix {} \; 2>/dev/null
dos2unix /usr/bin/menu /usr/bin/m-* /usr/bin/add-* /usr/bin/del-* 2>/dev/null

# Telegram Bot (riyanbot)
cat > /usr/bin/riyanbot << 'PYEOF'
#!/usr/bin/env python3
import asyncio, subprocess, base64
from aiogram import Bot, Dispatcher, types
from aiogram.filters import Command
from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton

BOT_TOKEN = ""
ADMIN_ID = 0
DOMAIN = ""

def load_cfg():
    global BOT_TOKEN, ADMIN_ID, DOMAIN
    try:
        with open('/var/lib/riyanbot.conf') as f:
            for line in f:
                if 'BOT_TOKEN' in line: BOT_TOKEN = line.split('=')[1].strip().strip('"')
                if 'ADMIN_ID' in line: ADMIN_ID = int(line.split('=')[1].strip())
                if 'DOMAIN' in line: DOMAIN = line.split('=')[1].strip().strip('"')
    except: pass

load_cfg()
bot = Bot(token=BOT_TOKEN)
dp = Dispatcher()

def run(cmd, t=30):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=t)
        out = (r.stdout + r.stderr).strip()
        return out[:3500] if out else "Done"
    except: return "Error"

def adm(uid): return uid == ADMIN_ID

def mkb():
    return InlineKeyboardMarkup(inline_keyboard=[
        [InlineKeyboardButton(text="🔐 SSH", callback_data="menu_ssh"),
         InlineKeyboardButton(text="💎 VLESS", callback_data="menu_vless")],
        [InlineKeyboardButton(text="🌀 VMess", callback_data="menu_vmess"),
         InlineKeyboardButton(text="🛡 Trojan", callback_data="menu_trojan")],
        [InlineKeyboardButton(text="📊 Status", callback_data="status"),
         InlineKeyboardButton(text="🔄 Restart", callback_data="restart")],
        [InlineKeyboardButton(text="💾 RAM", callback_data="ram"),
         InlineKeyboardButton(text="👥 Users", callback_data="users")],
    ])

def mktxt():
    ip = run("curl -s ifconfig.me")
    domain = run("cat /etc/xray/domain")
    return f"🚀 *Riyan VPS Bot*\n━━━━━━━━━━━━\n🌐 `{domain}`\n📡 `{ip}`\n━━━━━━━━━━━━"

def bk(cb): return InlineKeyboardMarkup(inline_keyboard=[[InlineKeyboardButton(text="🔙 Back", callback_data=cb)]])

@dp.message(Command("start"))
async def start(msg: types.Message):
    if not adm(msg.from_user.id): return
    await msg.answer(mktxt(), parse_mode="Markdown", reply_markup=mkb())

@dp.callback_query()
async def cb(call: types.CallbackQuery):
    if not adm(call.from_user.id): return
    d = call.data
    if d == "status":
        s = ""
        for svc,name in [("xray","Xray"),("nginx","Nginx"),("ssh","SSH"),("badvpn","BadVPN"),("ssh-ws","SSH-WS")]:
            act = run(f"systemctl is-active {svc}")
            s += f"{'✅' if act=='active' else '❌'} {name}\n"
        cpu = run("top -bn1 | grep 'Cpu' | awk '{print 100-$8\"%\"}'")
        ram = run("free -m | awk 'NR==2{printf \"%s/%sMB\",$3,$2}'")
        await call.message.edit_text(f"📊 *Status*\n━━━━━━━━━━\n{s}━━━━━━━━━━\nCPU: {cpu}\nRAM: {ram}", parse_mode="Markdown", reply_markup=bk("back"))
    elif d == "restart":
        run("systemctl restart xray nginx ssh badvpn ssh-ws")
        await call.message.edit_text("✅ All restarted!", reply_markup=bk("back"))
    elif d == "ram":
        run("sync && echo 3 > /proc/sys/vm/drop_caches")
        r = run("free -m | awk 'NR==2{printf \"%s/%sMB\",$3,$2}'")
        await call.message.edit_text(f"✅ RAM: {r}", reply_markup=bk("back"))
    elif d == "users":
        r = run("grep -oP '\"email\": \"\\K[^\"]+' /etc/xray/config.json | sort -u")
        await call.message.edit_text(f"👥 *Users:*\n```\n{r or 'No users'}\n```", parse_mode="Markdown", reply_markup=bk("back"))
    elif d == "menu_vless":
        kb = InlineKeyboardMarkup(inline_keyboard=[
            [InlineKeyboardButton(text="➕ Create", callback_data="vl_c"),
             InlineKeyboardButton(text="🗑 Delete", callback_data="vl_d")],
            [InlineKeyboardButton(text="📋 List", callback_data="vl_l"),
             InlineKeyboardButton(text="🔙 Back", callback_data="back")]])
        await call.message.edit_text("💎 *VLESS*\n`/add_vless user days`\n`/del_vless user`", parse_mode="Markdown", reply_markup=kb)
    elif d == "vl_c":
        await call.message.edit_text("💎 Send:\n`/add_vless username days`\nExample: `/add_vless riyan 30`", parse_mode="Markdown", reply_markup=bk("menu_vless"))
    elif d == "vl_d":
        await call.message.edit_text("🗑 Send:\n`/del_vless username`", parse_mode="Markdown", reply_markup=bk("menu_vless"))
    elif d == "vl_l":
        r = run("grep 'Remarks' /etc/log-create-vless.log 2>/dev/null | awk '{print NR\". \"$3}' | head -20")
        await call.message.edit_text(f"💎 *VLESS:*\n```\n{r or 'No users'}\n```", parse_mode="Markdown", reply_markup=bk("menu_vless"))
    elif d == "menu_trojan":
        kb = InlineKeyboardMarkup(inline_keyboard=[
            [InlineKeyboardButton(text="➕ Create", callback_data="tr_c"),
             InlineKeyboardButton(text="🗑 Delete", callback_data="tr_d")],
            [InlineKeyboardButton(text="📋 List", callback_data="tr_l"),
             InlineKeyboardButton(text="🔙 Back", callback_data="back")]])
        await call.message.edit_text("🛡 *Trojan*\n`/add_trojan user days`\n`/del_trojan user`", parse_mode="Markdown", reply_markup=kb)
    elif d == "tr_c":
        await call.message.edit_text("🛡 Send:\n`/add_trojan username days`", parse_mode="Markdown", reply_markup=bk("menu_trojan"))
    elif d == "tr_d":
        await call.message.edit_text("🗑 Send:\n`/del_trojan username`", parse_mode="Markdown", reply_markup=bk("menu_trojan"))
    elif d == "tr_l":
        r = run("grep 'Remarks' /etc/log-create-trojan.log 2>/dev/null | awk '{print NR\". \"$3}' | head -20")
        await call.message.edit_text(f"🛡 *Trojan:*\n```\n{r or 'No users'}\n```", parse_mode="Markdown", reply_markup=bk("menu_trojan"))
    elif d == "menu_vmess":
        kb = InlineKeyboardMarkup(inline_keyboard=[
            [InlineKeyboardButton(text="➕ Create", callback_data="vm_c"),
             InlineKeyboardButton(text="🗑 Delete", callback_data="vm_d")],
            [InlineKeyboardButton(text="📋 List", callback_data="vm_l"),
             InlineKeyboardButton(text="🔙 Back", callback_data="back")]])
        await call.message.edit_text("🌀 *VMess*\n`/add_vmess user days`", parse_mode="Markdown", reply_markup=kb)
    elif d == "vm_c":
        await call.message.edit_text("🌀 Send:\n`/add_vmess username days`", parse_mode="Markdown", reply_markup=bk("menu_vmess"))
    elif d == "vm_l":
        r = run("grep 'Remarks' /etc/log-create-vmess.log 2>/dev/null | awk '{print NR\". \"$3}' | head -20")
        await call.message.edit_text(f"🌀 *VMess:*\n```\n{r or 'No users'}\n```", parse_mode="Markdown", reply_markup=bk("menu_vmess"))
    elif d == "menu_ssh":
        kb = InlineKeyboardMarkup(inline_keyboard=[
            [InlineKeyboardButton(text="➕ Create", callback_data="ssh_c"),
             InlineKeyboardButton(text="🗑 Delete", callback_data="ssh_d")],
            [InlineKeyboardButton(text="📋 List", callback_data="ssh_l"),
             InlineKeyboardButton(text="🔙 Back", callback_data="back")]])
        await call.message.edit_text("🔐 *SSH*\n`/add_ssh user days`\n`/del_ssh user`", parse_mode="Markdown", reply_markup=kb)
    elif d == "ssh_c":
        await call.message.edit_text("🔐 Send:\n`/add_ssh username days`", parse_mode="Markdown", reply_markup=bk("menu_ssh"))
    elif d == "ssh_l":
        r = run("awk -F: '$3>=1000 && $1!=\"nobody\" {print NR\". \"$1}' /etc/passwd | head -20")
        await call.message.edit_text(f"🔐 *SSH:*\n```\n{r or 'No users'}\n```", parse_mode="Markdown", reply_markup=bk("menu_ssh"))
    elif d == "back":
        await call.message.edit_text(mktxt(), parse_mode="Markdown", reply_markup=mkb())
    await call.answer()

@dp.message(Command("add_vless"))
async def add_vless(msg: types.Message):
    if not adm(msg.from_user.id): return
    args = msg.text.split()
    if len(args) < 3: await msg.answer("Usage: /add_vless username days"); return
    user, days = args[1], args[2]
    await msg.answer(f"⏳ Creating VLESS: `{user}`...", parse_mode="Markdown")
    UUID = run("cat /proc/sys/kernel/random/uuid").strip()
    EXP = run(f"date -d '{days} days' +%Y-%m-%d").strip()
    DOMAIN = run("cat /etc/xray/domain").strip()
    run(f"""python3 -c "
import json
with open('/etc/xray/config.json') as f: c=json.load(f)
for i in c['inbounds']:
    if i.get('tag') in ['vless-ws','vless-grpc']:
        i['settings']['clients'].append({{'id':'{UUID}','email':'{user}'}})
with open('/etc/xray/config.json','w') as f: json.dump(c,f,indent=2)
" && cp /etc/xray/config.json /usr/local/etc/xray/config.json && systemctl restart xray""")
    run(f"echo 'Remarks : {user}' >> /etc/log-create-vless.log; echo 'Expired : {EXP}' >> /etc/log-create-vless.log")
    await msg.answer(f"""✅ *VLESS Created!*
━━━━━━━━━━━━━━
👤 User    : `{user}`
🔑 UUID    : `{UUID}`
🌐 Domain  : `{DOMAIN}`
📅 Expired : `{EXP}`
━━━━━━━━━━━━━━
🔗 *WS TLS:*
`vless://{UUID}@{DOMAIN}:443?path=/vless&security=tls&encryption=none&type=ws#{user}`
━━━━━━━━━━━━━━
🔗 *gRPC:*
`vless://{UUID}@{DOMAIN}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni={DOMAIN}#{user}`""", parse_mode="Markdown")

@dp.message(Command("add_trojan"))
async def add_trojan(msg: types.Message):
    if not adm(msg.from_user.id): return
    args = msg.text.split()
    if len(args) < 3: await msg.answer("Usage: /add_trojan username days"); return
    user, days = args[1], args[2]
    await msg.answer(f"⏳ Creating Trojan: `{user}`...", parse_mode="Markdown")
    UUID = run("cat /proc/sys/kernel/random/uuid").strip()
    EXP = run(f"date -d '{days} days' +%Y-%m-%d").strip()
    DOMAIN = run("cat /etc/xray/domain").strip()
    run(f"""python3 -c "
import json
with open('/etc/xray/config.json') as f: c=json.load(f)
for i in c['inbounds']:
    if i.get('tag') in ['trojan-ws','trojan-grpc']:
        i['settings']['clients'].append({{'password':'{UUID}','email':'{user}'}})
with open('/etc/xray/config.json','w') as f: json.dump(c,f,indent=2)
" && cp /etc/xray/config.json /usr/local/etc/xray/config.json && systemctl restart xray""")
    run(f"echo 'Remarks : {user}' >> /etc/log-create-trojan.log; echo 'Expired : {EXP}' >> /etc/log-create-trojan.log")
    await msg.answer(f"""✅ *Trojan Created!*
━━━━━━━━━━━━━━
👤 User     : `{user}`
🔑 Password : `{UUID}`
🌐 Domain   : `{DOMAIN}`
📅 Expired  : `{EXP}`
━━━━━━━━━━━━━━
🔗 *WS TLS:*
`trojan://{UUID}@{DOMAIN}:443?path=%2Ftrojan-ws&security=tls&host={DOMAIN}&type=ws&sni={DOMAIN}#{user}`
━━━━━━━━━━━━━━
🔗 *gRPC:*
`trojan://{UUID}@{DOMAIN}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni={DOMAIN}#{user}`""", parse_mode="Markdown")

@dp.message(Command("add_vmess"))
async def add_vmess(msg: types.Message):
    if not adm(msg.from_user.id): return
    args = msg.text.split()
    if len(args) < 3: await msg.answer("Usage: /add_vmess username days"); return
    user, days = args[1], args[2]
    await msg.answer(f"⏳ Creating VMess: `{user}`...", parse_mode="Markdown")
    UUID = run("cat /proc/sys/kernel/random/uuid").strip()
    EXP = run(f"date -d '{days} days' +%Y-%m-%d").strip()
    DOMAIN = run("cat /etc/xray/domain").strip()
    run(f"""python3 -c "
import json
with open('/etc/xray/config.json') as f: c=json.load(f)
for i in c['inbounds']:
    if i.get('tag') in ['vmess-ws','vmess-grpc']:
        i['settings']['clients'].append({{'id':'{UUID}','alterId':0,'email':'{user}'}})
with open('/etc/xray/config.json','w') as f: json.dump(c,f,indent=2)
" && cp /etc/xray/config.json /usr/local/etc/xray/config.json && systemctl restart xray""")
    vmess_json = f'{{"v":"2","ps":"{user}","add":"{DOMAIN}","port":"443","id":"{UUID}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"tls"}}'
    vmess_b64 = base64.b64encode(vmess_json.encode()).decode()
    run(f"echo 'Remarks : {user}' >> /etc/log-create-vmess.log; echo 'Expired : {EXP}' >> /etc/log-create-vmess.log")
    await msg.answer(f"""✅ *VMess Created!*
━━━━━━━━━━━━━━
👤 User    : `{user}`
🔑 UUID    : `{UUID}`
🌐 Domain  : `{DOMAIN}`
📅 Expired : `{EXP}`
━━━━━━━━━━━━━━
🔗 *Link:*
`vmess://{vmess_b64}`""", parse_mode="Markdown")

@dp.message(Command("add_ssh"))
async def add_ssh(msg: types.Message):
    if not adm(msg.from_user.id): return
    args = msg.text.split()
    if len(args) < 3: await msg.answer("Usage: /add_ssh username days"); return
    user, days = args[1], args[2]
    PASS = run("openssl rand -base64 8").strip()
    EXP = run(f"date -d '{days} days' +%Y-%m-%d").strip()
    IP = run("curl -s ifconfig.me").strip()
    DOMAIN = run("cat /etc/xray/domain").strip()
    run(f"useradd -e {EXP} -s /bin/false -M {user} 2>/dev/null; echo '{user}:{PASS}' | chpasswd")
    await msg.answer(f"""✅ *SSH Created!*
━━━━━━━━━━━━━━
👤 User    : `{user}`
🔑 Pass    : `{PASS}`
📡 IP      : `{IP}`
🌐 Host    : `{DOMAIN}`
🔌 SSH     : `22, 143`
🔌 WS      : `80 (via 443)`
📅 Expired : `{EXP}`
━━━━━━━━━━━━━━
📦 *Payload WS:*
`GET / HTTP/1.1[crlf]Host: {DOMAIN}[crlf]Upgrade: websocket[crlf][crlf]`
📦 *Payload WSS:*
`GET wss://bug.com HTTP/1.1[crlf]Host: {DOMAIN}[crlf]Upgrade: websocket[crlf][crlf]`""", parse_mode="Markdown")

@dp.message(Command("del_vless"))
async def del_vless(msg: types.Message):
    if not adm(msg.from_user.id): return
    args = msg.text.split()
    if len(args) < 2: await msg.answer("Usage: /del_vless username"); return
    user = args[1]
    run(f"""python3 -c "
import json
with open('/etc/xray/config.json') as f: c=json.load(f)
for i in c['inbounds']:
    if 'clients' in i.get('settings',{{}}):
        i['settings']['clients']=[x for x in i['settings']['clients'] if x.get('email')!='{user}']
with open('/etc/xray/config.json','w') as f: json.dump(c,f,indent=2)
" && cp /etc/xray/config.json /usr/local/etc/xray/config.json && systemctl restart xray""")
    await msg.answer(f"✅ VLESS `{user}` deleted!", parse_mode="Markdown")

@dp.message(Command("del_trojan"))
async def del_trojan(msg: types.Message):
    if not adm(msg.from_user.id): return
    args = msg.text.split()
    if len(args) < 2: await msg.answer("Usage: /del_trojan username"); return
    user = args[1]
    run(f"""python3 -c "
import json
with open('/etc/xray/config.json') as f: c=json.load(f)
for i in c['inbounds']:
    if 'clients' in i.get('settings',{{}}):
        i['settings']['clients']=[x for x in i['settings']['clients'] if x.get('email')!='{user}']
with open('/etc/xray/config.json','w') as f: json.dump(c,f,indent=2)
" && cp /etc/xray/config.json /usr/local/etc/xray/config.json && systemctl restart xray""")
    await msg.answer(f"✅ Trojan `{user}` deleted!", parse_mode="Markdown")

@dp.message(Command("del_ssh"))
async def del_ssh(msg: types.Message):
    if not adm(msg.from_user.id): return
    args = msg.text.split()
    if len(args) < 2: await msg.answer("Usage: /del_ssh username"); return
    run(f"userdel -f {args[1]} 2>&1")
    await msg.answer(f"✅ SSH `{args[1]}` deleted!", parse_mode="Markdown")

@dp.message(Command("setup"))
async def setup_bot(msg: types.Message):
    args = msg.text.split()
    if len(args) < 3:
        await msg.answer("Usage: /setup BOT_TOKEN ADMIN_ID")
        return
    token, admin = args[1], args[2]
    with open('/var/lib/riyanbot.conf', 'w') as f:
        f.write(f'BOT_TOKEN="{token}"\nADMIN_ID={admin}\nDOMAIN=""\n')
    await msg.answer("✅ Config saved! Restart bot: `screen -S riyanbot -X quit && screen -dmS riyanbot python3 /usr/bin/riyanbot`", parse_mode="Markdown")

async def main():
    load_cfg()
    if not BOT_TOKEN:
        print("❌ No token! Send /setup TOKEN ADMIN_ID to your bot first")
        print("Or create /var/lib/riyanbot.conf with BOT_TOKEN and ADMIN_ID")
        return
    print(f"🚀 Riyan Bot started! Admin: {ADMIN_ID}")
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
PYEOF
chmod +x /usr/bin/riyanbot

# Bot service
cat > /etc/systemd/system/riyanbot.service << REOF
[Unit]
Description=Riyan VPS Telegram Bot
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/bin/riyanbot
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
REOF

# Enable and start all services
systemctl daemon-reload
systemctl enable nginx xray ssh-ws badvpn riyanbot 2>/dev/null
systemctl start nginx xray ssh-ws badvpn riyanbot 2>/dev/null

echo ""
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;32m   ✅ Riyan VPS VPN Install Complete!   \e[0m"
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo ""
echo -e "Domain  : $(cat /etc/xray/domain)"
echo -e "Menu    : type 'menu'"
echo ""
echo -e "Telegram Bot Setup:"
echo -e "1. Start your bot on Telegram"
echo -e "2. Send: /setup YOUR_TOKEN YOUR_TELEGRAM_ID"
echo ""
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e " Script By Riyan | t.me/RiyanFF"
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
