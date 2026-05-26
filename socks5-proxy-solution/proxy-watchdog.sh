#!/bin/bash

# ==============================================================
#   SOCKS5 Proxy Health Watchdog
#   Monitors danted every 60 seconds and restarts if offline
# ==============================================================

set -u  # Exit on undefined variable

# Configuration
PROXY_PORT="${1:-1080}"
PROXY_USER="${2:-proxyuser}"
PROXY_PASS="${3:-proxy@123}"
CHECK_INTERVAL=60
LOGFILE="/var/log/proxy-watchdog.log"
MAX_RESTART_ATTEMPTS=3
RESTART_COOLDOWN=300

# Track restarts to prevent restart loop
RESTART_COUNT=0
LAST_RESTART_TIME=0

# -------- Logging Function --------
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

# -------- Check if danted process is running --------
is_process_running() {
    pgrep -x "danted" > /dev/null 2>&1
    return $?
}

# -------- Check if proxy port is listening --------
is_port_listening() {
    netstat -tuln 2>/dev/null | grep -q ":${PROXY_PORT} " || \
    ss -tuln 2>/dev/null | grep -q ":${PROXY_PORT} "
    return $?
}

# -------- Test proxy connectivity --------
test_proxy_connection() {
    # Try to connect to proxy port
    timeout 5 bash -c "cat < /dev/null > /dev/tcp/localhost/${PROXY_PORT}" 2>/dev/null
    return $?
}

# -------- Restart proxy with backoff --------
restart_proxy() {
    local now=$(date +%s)
    local time_since_restart=$((now - LAST_RESTART_TIME))
    
    # Check cooldown to prevent restart loop
    if [ $RESTART_COUNT -ge $MAX_RESTART_ATTEMPTS ] && [ $time_since_restart -lt $RESTART_COOLDOWN ]; then
        log "ERROR: Too many restarts in short time. Waiting ${RESTART_COOLDOWN}s before retry."
        return 1
    fi
    
    # Reset counter if cooldown passed
    if [ $time_since_restart -ge $RESTART_COOLDOWN ]; then
        RESTART_COUNT=0
    fi
    
    log "WARNING: Proxy is offline. Attempting restart (#$((RESTART_COUNT + 1)))..."
    
    systemctl restart danted
    RESTART_COUNT=$((RESTART_COUNT + 1))
    LAST_RESTART_TIME=$now
    
    # Wait for service to start
    sleep 3
    
    if is_port_listening; then
        log "SUCCESS: Proxy restarted and port ${PROXY_PORT} is listening"
        return 0
    else
        log "ERROR: Proxy restart failed - port not listening"
        return 1
    fi
}

# -------- Main monitoring loop --------
log "Starting SOCKS5 Proxy Health Watchdog (Port: ${PROXY_PORT}, Interval: ${CHECK_INTERVAL}s)"

while true; do
    # Check multiple indicators of proxy health
    if ! is_process_running; then
        log "ALERT: danted process not running"
        restart_proxy
    elif ! is_port_listening; then
        log "ALERT: danted port ${PROXY_PORT} not listening"
        restart_proxy
    elif ! test_proxy_connection; then
        log "ALERT: Cannot connect to port ${PROXY_PORT}"
        restart_proxy
    else
        # Proxy is healthy
        echo "[$(date '+%H:%M:%S')] ✓ Proxy OK - Process running, port listening" >> "$LOGFILE"
    fi
    
    # Wait before next check
    sleep "$CHECK_INTERVAL"
done
