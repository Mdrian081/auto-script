#!/bin/bash

# SSH Keepalive - VPS disconnect সমস্যা fix
SSHD_CONFIG="/etc/ssh/sshd_config"

# ClientAliveInterval এবং ClientAliveCountMax set করি
if grep -q "ClientAliveInterval" "$SSHD_CONFIG"; then
    sed -i 's/.*ClientAliveInterval.*/ClientAliveInterval 60/' "$SSHD_CONFIG"
else
    echo "ClientAliveInterval 60" >> "$SSHD_CONFIG"
fi

if grep -q "ClientAliveCountMax" "$SSHD_CONFIG"; then
    sed -i 's/.*ClientAliveCountMax.*/ClientAliveCountMax 10/' "$SSHD_CONFIG"
else
    echo "ClientAliveCountMax 10" >> "$SSHD_CONFIG"
fi

if grep -q "TCPKeepAlive" "$SSHD_CONFIG"; then
    sed -i 's/.*TCPKeepAlive.*/TCPKeepAlive yes/' "$SSHD_CONFIG"
else
    echo "TCPKeepAlive yes" >> "$SSHD_CONFIG"
fi

systemctl restart sshd > /dev/null 2>&1

echo -e "\e[32m[✓] SSH Keepalive configured - VPS disconnect problem fixed!\e[0m"
echo -e "\e[32m[✓] VPS will stay connected longer now\e[0m"
