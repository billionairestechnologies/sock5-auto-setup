#!/bin/bash

# ================================================
#   SOCKS5 Proxy Auto-Install Script
#   For GCP Ubuntu VMs (Billionaires Infra)
#   Auto-starts on VM boot/restart
# ================================================

set -e  # Exit on any error

echo ""
echo "========================================"
echo "  SOCKS5 Proxy Installer - Dante"
echo "========================================"
echo ""

# ---- CONFIG (Change these if needed) ----
PROXY_USER="proxyuser"
PROXY_PASS="proxy@123"
PROXY_PORT="1080"
# -----------------------------------------

# Step 1: Update system
echo "[1/6] Updating system packages..."
apt update -y -q

# Step 2: Install required packages (including nano)
echo "[2/6] Installing dante-server and tools..."
apt install -y -q dante-server nano curl

# Step 3: Create proxy user (skip if already exists)
echo "[3/6] Creating proxy user..."
if id "$PROXY_USER" &>/dev/null; then
    echo "  User '$PROXY_USER' already exists, updating password..."
else
    useradd -r -s /bin/false "$PROXY_USER"
    echo "  User '$PROXY_USER' created."
fi
echo "$PROXY_USER:$PROXY_PASS" | chpasswd

# Step 4: Auto-detect network interface
echo "[4/6] Detecting network interface..."
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
echo "  Detected interface: $INTERFACE"

# Step 5: Write Dante config
echo "[5/6] Writing Dante configuration..."

# Backup old config if it exists
[ -f /etc/danted.conf ] && cp /etc/danted.conf /etc/danted.conf.bak

cat > /etc/danted.conf <<EOF
logoutput: syslog

# Listen on all interfaces
internal: 0.0.0.0 port = ${PROXY_PORT}

# Use VM's default outbound interface
external: ${INTERFACE}

# Allow both auth and no-auth (update to 'username' only for security)
socksmethod: username none

user.privileged: root
user.notprivileged: nobody

# Allow all client connections
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect
}

# Allow all outbound SOCKS connections
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
}
EOF

echo "  Config written at /etc/danted.conf"

# Step 6: Enable + Start service
echo "[6/6] Enabling and starting Dante service..."
systemctl enable danted
systemctl restart danted

# Optional: Open port if UFW is installed
if command -v ufw &>/dev/null; then
    ufw allow ${PROXY_PORT}/tcp
    echo "  UFW firewall rule added for port ${PROXY_PORT}"
fi

# Final status check
echo ""
echo "========================================"
echo "  PROXY SETUP COMPLETE"
echo "========================================"
echo ""
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Check GCP Console")
echo "  External IP  : $EXTERNAL_IP"
echo "  Port         : ${PROXY_PORT}"
echo "  Username     : ${PROXY_USER}"
echo "  Password     : ${PROXY_PASS}"
echo "  Type         : SOCKS5"
echo ""
echo "  Proxy string : socks5://${PROXY_USER}:${PROXY_PASS}@${EXTERNAL_IP}:${PROXY_PORT}"
echo ""
echo "========================================"
systemctl status danted --no-pager
echo ""
