#!/bin/bash

# ==============================================================
#   Proxy Status & Health Check Dashboard
#   Run: ./proxy-status.sh
# ==============================================================

PROXY_PORT="${1:-1080}"
PROXY_USER="${2:-proxyuser}"
PROXY_PASS="${3:-proxy@123}"

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║       SOCKS5 Proxy Status & Health Check               ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# -------- Check 1: Process Status --------
echo "[1] Process Status"
if pgrep -x "danted" > /dev/null; then
    PID=$(pgrep -x "danted")
    echo "    ✓ danted process running (PID: $PID)"
    
    # Show process info
    ps aux | grep "[d]anted" | awk '{printf "    Memory: %s | CPU: %s%%\n", $6, $3}'
else
    echo "    ✗ danted process NOT running"
fi
echo ""

# -------- Check 2: Port Status --------
echo "[2] Port Status (${PROXY_PORT})"
if netstat -tuln 2>/dev/null | grep -q ":${PROXY_PORT} " || ss -tuln 2>/dev/null | grep -q ":${PROXY_PORT} "; then
    echo "    ✓ Port ${PROXY_PORT} is LISTENING"
    
    # Count connections
    CONN_COUNT=$(netstat -an 2>/dev/null | grep -c ":${PROXY_PORT}" || ss -an 2>/dev/null | grep -c ":${PROXY_PORT}")
    echo "    Active connections: $CONN_COUNT"
else
    echo "    ✗ Port ${PROXY_PORT} is NOT listening"
fi
echo ""

# -------- Check 3: Network Connectivity --------
echo "[3] Network Connectivity Test"
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/localhost/${PROXY_PORT}" 2>/dev/null; then
    echo "    ✓ Can connect to port ${PROXY_PORT}"
else
    echo "    ✗ Cannot connect to port ${PROXY_PORT}"
fi
echo ""

# -------- Check 4: Service Status --------
echo "[4] Systemd Service Status"
systemctl is-active --quiet danted && echo "    ✓ danted service is ACTIVE" || echo "    ✗ danted service is INACTIVE"
systemctl is-enabled --quiet danted && echo "    ✓ danted service is ENABLED (auto-start)" || echo "    ✗ danted service is DISABLED"

echo ""

# -------- Check 5: Watchdog Status --------
echo "[5] Health Watchdog Status"
if pgrep -f "proxy-watchdog" > /dev/null; then
    echo "    ✓ Watchdog process is running"
else
    echo "    ✗ Watchdog process NOT running"
fi

if systemctl is-active --quiet proxy-watchdog; then
    echo "    ✓ Watchdog service is ACTIVE"
else
    echo "    ✗ Watchdog service is INACTIVE"
fi
echo ""

# -------- Check 6: Recent Logs --------
echo "[6] Recent Activity Logs"
echo "    --- Last 5 restarts (if any) ---"
grep -i "restart" /var/log/proxy-watchdog.log 2>/dev/null | tail -5 | sed 's/^/    /'
echo ""
echo "    --- Last 5 errors (if any) ---"
grep -i "error\|alert\|warning" /var/log/proxy-watchdog.log 2>/dev/null | tail -5 | sed 's/^/    /'
echo ""

# -------- Check 7: File Descriptor Usage --------
echo "[7] System Resource Usage"
if [ -e /proc/sys/fs/file-max ]; then
    FILE_MAX=$(cat /proc/sys/fs/file-max)
    echo "    Max file descriptors: $FILE_MAX"
fi

if pgrep -x "danted" > /dev/null; then
    PID=$(pgrep -x "danted")
    if [ -d "/proc/$PID/fd" ]; then
        FD_COUNT=$(ls -1 /proc/$PID/fd 2>/dev/null | wc -l)
        echo "    danted open file descriptors: $FD_COUNT"
    fi
fi
echo ""

# -------- Overall Status --------
echo "╔════════════════════════════════════════════════════════╗"
if pgrep -x "danted" > /dev/null && \
   (netstat -tuln 2>/dev/null | grep -q ":${PROXY_PORT} " || ss -tuln 2>/dev/null | grep -q ":${PROXY_PORT} "); then
    echo "║                   STATUS: ✓ HEALTHY                     ║"
else
    echo "║                   STATUS: ✗ OFFLINE                     ║"
fi
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Quick test with proxy
echo "[BONUS] Quick Proxy Test (if you have curl + socks5 support):"
echo "    Command: curl --proxy socks5://${PROXY_USER}:${PROXY_PASS}@localhost:${PROXY_PORT} https://ifconfig.me"
echo "    Expected: Your VM's external IP address"
echo ""
