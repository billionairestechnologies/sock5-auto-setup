# SOCKS5 Proxy Troubleshooting & Diagnostics

## Diagnostic Checklist

Run this when proxy isn't working:

```bash
# 1. Check if danted is running
systemctl status danted-ha

# 2. Check if port is listening
netstat -tuln | grep 1080
# OR
ss -tuln | grep 1080

# 3. Test local connection
telnet localhost 1080

# 4. Check logs
sudo tail -50 /var/log/proxy-watchdog.log
sudo tail -50 /var/log/danted.log

# 5. Check system resources
free -h
df -h
ps aux | grep danted
```

---

## Common Issues & Solutions

### Issue 1: "Proxy goes offline after hours"

**Root Cause**: In the old setup, the `danted` process crashes but systemd doesn't restart it automatically.

**Solution (HA Setup)**:
- Systemd has `Restart=always` with backoff
- Watchdog monitors every 60 seconds
- Should not happen anymore

**If still happens**:
```bash
# Check service status
sudo systemctl status danted-ha

# Check logs for crash reason
sudo journalctl -u danted-ha -n 100

# Check system resources
free -h  # Check for memory issues
df -h    # Check disk space
```

---

### Issue 2: "Proxy starts but then dies within minutes"

**Symptoms**: Service starts, works briefly, then crashes

**Causes**:
- Port already in use
- Firewall blocking
- Configuration error
- System resource limits

**Fix**:
```bash
# 1. Check if port is free
sudo lsof -i :1080

# 2. Check system logs
sudo journalctl -u danted-ha -f

# 3. Verify config is valid
danted -V  # Version check
sudo /usr/sbin/danted -f /etc/danted.conf -D  # Test config

# 4. Check firewall
sudo ufw status
sudo ufw allow 1080/tcp
```

---

### Issue 3: "Watchdog keeps restarting the proxy"

**Symptom**: Log shows many restarts per minute

**Causes**:
- Configuration error
- Port conflict
- Resource exhaustion
- Network issues

**Diagnose**:
```bash
# Check watchdog logs
tail -f /var/log/proxy-watchdog.log

# Look for pattern of restarts
grep "Restarting" /var/log/proxy-watchdog.log | wc -l

# Check system metrics
top -b -n 1 | head -20
```

**Fix**:
```bash
# Stop watchdog temporarily
sudo systemctl stop proxy-watchdog.service

# Get danted to stay running
sudo systemctl restart danted-ha
sleep 5

# Check if it stays running
ps aux | grep danted

# If it crashes, check the error
sudo journalctl -u danted-ha -n 100

# Re-enable watchdog when fixed
sudo systemctl start proxy-watchdog.service
```

---

### Issue 4: "Port 1080 not listening"

**Check**:
```bash
# List all listening ports
sudo netstat -tuln | grep LISTEN
# OR
sudo ss -tuln | grep LISTEN

# Specifically check for 1080
sudo netstat -tuln | grep :1080
sudo ss -tuln | grep :1080
```

**If not there**:
```bash
# Check if process is running
ps aux | grep danted

# Check service status
sudo systemctl status danted-ha

# Restart service
sudo systemctl restart danted-ha

# Wait and check again
sleep 3
sudo netstat -tuln | grep :1080
```

---

### Issue 5: "Can't connect from client"

**Test locally first**:
```bash
# From the VPS itself
curl --proxy socks5://proxyuser:proxy@123@localhost:1080 https://ifconfig.me

# If that works, it's a firewall issue
```

**Firewall fixes**:
```bash
# If using UFW
sudo ufw allow 1080/tcp
sudo ufw allow 1080/udp

# If using GCP firewall, add ingress rule in console

# If using security groups (AWS), add port 1080
```

---

### Issue 6: "High memory or CPU usage"

**Check current usage**:
```bash
# Memory
ps aux | grep danted | grep -v grep

# Top processes
top -b -n 1 | head -15

# Danted connection count
netstat -an | grep :1080 | wc -l
# OR
ss -an | grep :1080 | wc -l
```

**Reduce usage**:
```bash
# Lower connection limit in /etc/danted.conf
sudo nano /etc/danted.conf

# Find: maxchild: 10000
# Change to: maxchild: 5000

# Reduce timeout.io (idle connection cleanup)
# Find: timeout.io: 600
# Change to: timeout.io: 300

# Restart
sudo systemctl restart danted-ha
```

---

### Issue 7: "Errors in logs"

**View detailed logs**:
```bash
# Recent danted errors
sudo journalctl -u danted-ha -p err -n 50

# All recent activity
sudo journalctl -u danted-ha -n 100

# Follow in real-time
sudo journalctl -u danted-ha -f

# Watchdog logs
tail -50 /var/log/proxy-watchdog.log
```

**Common error messages**:

| Error | Cause | Fix |
|-------|-------|-----|
| `Permission denied` | Config file permissions | `sudo chmod 644 /etc/danted.conf` |
| `Address already in use` | Port conflict | Change port in config |
| `Cannot bind to port` | Firewall or permissions | Check firewall, run as sudo |
| `Too many open files` | File descriptor limit | Increase limits (see below) |

---

## Resource Management

### Increase File Descriptor Limits

```bash
# Check current limit
ulimit -n

# Permanent increase (edit)
sudo nano /etc/security/limits.conf

# Add these lines:
# * soft nofile 65535
# * hard nofile 65535

# Apply
ulimit -n 65535
```

### Monitor Active Connections

```bash
# Current connections
netstat -an | grep :1080 | wc -l
# OR
ss -an | grep :1080 | wc -l

# Watch in real-time
watch -n 1 'netstat -an | grep :1080 | wc -l'
```

### Clean Up Zombie Connections

```bash
# Show zombie processes
ps aux | grep defunct

# Force restart (will disconnect current clients)
sudo systemctl restart danted-ha
```

---

## Performance Optimization

### For High Traffic

Edit `/etc/danted.conf`:

```bash
sudo nano /etc/danted.conf
```

Increase limits:
```
maxchild: 20000          # Increase from 10000
timeout.io: 900          # Increase from 600 (keep connections longer)
timeout.connect: 60      # Increase from 30
```

Restart:
```bash
sudo systemctl restart danted-ha
```

### Monitor Performance

```bash
# Install monitoring tools
sudo apt install -y htop iotop nethogs

# Watch danted CPU/Memory
watch -n 5 'ps aux | grep danted | grep -v grep'

# Monitor network
sudo nethogs eth0

# Monitor disk I/O
sudo iotop
```

---

## Log Analysis

### Find Issues in Logs

```bash
# All errors in last 24 hours
sudo journalctl -u danted-ha --since "24 hours ago" | grep -i error

# Connection problems
sudo journalctl -u danted-ha | grep -i "connect\|refuse\|reset"

# Authentication failures
sudo journalctl -u danted-ha | grep -i "auth"

# From watchdog
grep "ERROR\|ALERT" /var/log/proxy-watchdog.log

# Count restarts
grep "SUCCESS.*restarted" /var/log/proxy-watchdog.log | wc -l
```

### Export Logs

```bash
# Save recent logs
sudo journalctl -u danted-ha -n 500 > /tmp/danted-logs.txt

# With timestamps
sudo journalctl -u danted-ha --all --output=json > /tmp/danted-logs.json

# Watchdog logs
cp /var/log/proxy-watchdog.log /tmp/watchdog-logs.txt
```

---

## Reset to Known-Good State

```bash
# Stop all services
sudo systemctl stop proxy-watchdog.service
sudo systemctl stop danted-ha

# Reset configuration
sudo cp /etc/danted.conf.bak /etc/danted.conf

# Clear old logs
sudo truncate -s 0 /var/log/proxy-watchdog.log
sudo truncate -s 0 /var/log/danted.log

# Restart services
sudo systemctl start danted-ha
sleep 2
sudo systemctl start proxy-watchdog.service

# Verify
proxy-status.sh
```

---

## Testing Commands

### Test Proxy (Python)

```python
import requests
proxies = {"http": "socks5://proxyuser:proxy@123@YOUR_VM_IP:1080",
           "https": "socks5://proxyuser:proxy@123@YOUR_VM_IP:1080"}
r = requests.get("https://ifconfig.me", proxies=proxies)
print(r.text)  # Should show VM IP
```

### Test Proxy (Curl)

```bash
curl --proxy socks5://proxyuser:proxy@123@YOUR_VM_IP:1080 https://ifconfig.me
```

### Test Proxy (Browser)

Install FoxyProxy extension, add:
- Type: SOCKS5
- Host: YOUR_VM_IP
- Port: 1080  
- Username: proxyuser
- Password: proxy@123

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `proxy-status.sh` | Full health check |
| `sudo systemctl status danted-ha` | Service status |
| `sudo journalctl -u danted-ha -f` | Real-time logs |
| `tail -f /var/log/proxy-watchdog.log` | Watchdog logs |
| `netstat -an \| grep :1080` | Check if listening |
| `curl --proxy socks5://...` | Test connectivity |
| `sudo systemctl restart danted-ha` | Restart proxy |
| `sudo systemctl stop proxy-watchdog.service` | Disable watchdog |

---

**Still having issues?** 
1. Run `proxy-status.sh` for quick diagnosis
2. Check `/var/log/proxy-watchdog.log` for recent restarts
3. Review `sudo journalctl -u danted-ha -n 50` for errors
4. Compare your setup with settings in this guide
