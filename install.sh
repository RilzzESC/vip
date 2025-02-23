#!/bin/bash

# Auto-Installer Trojan & VMess (V2Ray) + WebSocket + TLS
# Tested on Ubuntu 20.04/22.04

# Warna untuk output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Banner
clear
echo -e "${YELLOW}=============================================${NC}"
echo -e "${GREEN}  🚀 Auto-Installer Trojan & VMess 🚀  ${NC}"
echo -e "${YELLOW}=============================================${NC}"
sleep 2

# Menu utama
echo -e "${GREEN}Pilih menu:${NC}"
echo -e "1) Install Trojan & VMess"
echo -e "2) Hapus Instalasi"
echo -e "3) Keluar"
echo -n "Masukkan pilihan Anda: "
read -r MENU_CHOICE

case $MENU_CHOICE in
    1)
        echo -e "${GREEN}Memulai instalasi...${NC}"
        ;;
    2)
        echo -e "${RED}Menghapus instalasi...${NC}"
        systemctl stop trojan v2ray
        systemctl disable trojan v2ray
        rm -rf /etc/trojan /usr/local/etc/v2ray ~/.acme.sh
        echo -e "${GREEN}Uninstall selesai!${NC}"
        exit 0
        ;;
    3)
        echo -e "${YELLOW}Keluar...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Pilihan tidak valid!${NC}"
        exit 1
        ;;
esac

# Meminta input pengguna
echo -e "${GREEN}[?] Masukkan domain Anda: ${NC}"
read -r DOMAIN
echo -e "${GREEN}[?] Masukkan email Anda (untuk SSL): ${NC}"
read -r EMAIL
echo -e "${GREEN}[?] Masukkan path WebSocket untuk Trojan (misal: /trojan): ${NC}"
read -r TROJAN_PATH
echo -e "${GREEN}[?] Masukkan path WebSocket untuk VMess (misal: /vmess): ${NC}"
read -r VMESS_PATH

# Update & Install Dependencies
echo -e "${GREEN}[+] Updating system & installing dependencies...${NC}"
apt update && apt install -y curl wget sudo unzip socat cron bash-completion

# Install Acme.sh untuk SSL
echo -e "${GREEN}[+] Installing Acme.sh for SSL certificate...${NC}"
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --issue -d $DOMAIN --standalone -m $EMAIL --force
~/.acme.sh/acme.sh --installcert -d $DOMAIN --key-file /etc/trojan/private.key --fullchain-file /etc/trojan/cert.pem

# Install Trojan-GFW
echo -e "${GREEN}[+] Installing Trojan-GFW...${NC}"
bash -c "$(curl -fsSL https://git.io/JUUmK)"
systemctl stop trojan
cat > /etc/trojan/config.json <<EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "password": ["password123"],
    "ssl": {
        "cert": "/etc/trojan/cert.pem",
        "key": "/etc/trojan/private.key"
    },
    "websocket": {
        "enabled": true,
        "path": "$TROJAN_PATH"
    }
}
EOF
systemctl restart trojan
systemctl enable trojan

# Install V2Ray (VMess)
echo -e "${GREEN}[+] Installing V2Ray (VMess)...${NC}"
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
cat > /usr/local/etc/v2ray/config.json <<EOF
{
    "inbounds": [
        {
            "port": 443,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    { "id": "$(uuidgen)", "alterId": 0 }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": { "path": "$VMESS_PATH" },
                "security": "tls",
                "tlsSettings": {
                    "certificates": [
                        { "certificateFile": "/etc/trojan/cert.pem", "keyFile": "/etc/trojan/private.key" }
                    ]
                }
            }
        }
    ]
}
EOF
systemctl restart v2ray
systemctl enable v2ray

# Output Informasi
clear
echo -e "${YELLOW}=============================================${NC}"
echo -e "${GREEN} ✅ Instalasi Trojan & VMess Selesai! ✅ ${NC}"
echo -e "${YELLOW}=============================================${NC}"
echo -e "🔹 Domain: ${GREEN}$DOMAIN${NC}"
echo -e "🔹 Trojan Path: ${GREEN}$TROJAN_PATH${NC}"
echo -e "🔹 VMess Path: ${GREEN}$VMESS_PATH${NC}"
echo -e "🔹 Trojan Password: ${GREEN}password123${NC}"
echo -e "🔹 VMess UUID: ${GREEN}$(jq -r '.inbounds[0].settings.clients[0].id' /usr/local/etc/v2ray/config.json)${NC}"
echo -e ""
echo -e "${GREEN}🚀 Gunakan WebSocket + TLS di client Anda! 🚀${NC}"
