# SOCKS5 Proxy HA - Quick Reference Card

## 🚀 One-Command Deploy

```bash
curl -s https://raw.githubusercontent.com/billionairestechnologies/sock5-auto-setup/main/setup-proxy-ha.sh | sudo bash
```

Time: ~2 minutes | Result: Proxy live with auto-recovery

---

## ✅ Deployment Checklist

- [ ] SSH into Linux VPS
- [ ] Run installer command
- [ ] Wait 2 minutes for completion
- [ ] Run `proxy-status.sh`
- [ ] Verify status shows "HEALTHY"
- [ ] Test from client: `curl --proxy socks5://proxyuser:proxy@123@IP:1080 https://ifconfig.me`
- [ ] Verify client gets VM IP address
- [ ] Check logs: `tail -f /var/log/proxy-watchdog.log`
- [ ] Bookmark this reference card
- [ ] ✓ Done - proxy is production ready!

---

## 📊 Status Check

### Command
```bash
proxy-status.sh
```

### What to Look For
```
✓ Process running (PID: xxx)
✓ Port 1080 LISTENING
✓ Can connect to port
✓ Service ACTIVE
✓ Service ENABLED
✓ Watchdog running
✓ Watchdog service ACTIVE

STATUS: ✓ HEALTHY
```

### If Unhealthy
See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 🔧 Essential Commands

```bash
# Status
proxy-status.sh

# Logs
tail -f /var/log/proxy-watchdog.log          # Watchdog logs
sudo journalctl -u danted-ha -f              # Detailed service logs
tail -f /var/log/danted.log                  # Dante logs

# Control
sudo systemctl restart danted-ha             # Restart proxy
sudo systemctl stop proxy-watchdog.service   # Pause monitoring
sudo systemctl status danted-ha              # Service status

# Test
curl --proxy socks5://proxyuser:proxy@123@localhost:1080 https://ifconfig.me

# Info
sudo netstat -tuln | grep 1080               # Check if listening
ps aux | grep danted                         # Process info
free -h                                       # Memory usage
```

---

## 🎯 What Changed from Original?

| Aspect | Original | Now |
|--------|----------|-----|
| Crash recovery | ✗ Manual | ✓ Automatic |
| Monitoring | ✗ None | ✓ Every 60s |
| Downtime | Hours (manual restart) | <5 seconds (auto) |
| Logging | Basic | Comprehensive |
| Resource limits | None | Yes (prevents issues) |

---

## ⚠️ Common Issues & Fixes

### Proxy offline after hours

**Original issue fixed by this installer** ✓

### Too many restarts

```bash
# Check system resources
free -h              # Memory
df -h                # Disk
top -b -n 1          # CPU
```

### Can't connect from client

```bash
# Verify port is listening
sudo netstat -tuln | grep 1080

# Check firewall (GCP example)
# Console → VPC Network → Firewall → Add rule for port 1080

# Test locally first
curl --proxy socks5://proxyuser:proxy@123@localhost:1080 https://ifconfig.me
```

### Watchdog not running

```bash
sudo systemctl restart proxy-watchdog.service
sudo systemctl enable proxy-watchdog.service
```

See full guide: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 📈 Monitoring Essentials

### Real-time Watch
```bash
# Watch status every 5 seconds
watch -n 5 'proxy-status.sh'

# Watch logs
tail -f /var/log/proxy-watchdog.log

# Watch service
watch -n 5 'systemctl status danted-ha --no-pager'
```

### Health Metrics
```bash
# Connection count
netstat -an | grep :1080 | wc -l

# Restart count (last 24h)
grep "SUCCESS.*restarted" /var/log/proxy-watchdog.log | wc -l

# Error count
grep "ERROR\|ALERT" /var/log/proxy-watchdog.log | wc -l

# Uptime
ps -o etime= -p $(pgrep -x danted)
```

---

## 🔐 Security Notes

### Default Credentials (Change in Production)
- Username: `proxyuser`
- Password: `proxy@123`
- Port: `1080`

### To Change Port/Credentials
1. Edit `/etc/danted.conf`
2. Change values
3. `sudo systemctl restart danted-ha`

### Firewall Rules (GCP Console)
```
Name        : allow-socks5
Direction   : Ingress
Targets     : All instances
Source IP   : 0.0.0.0/0
Port        : tcp:1080
Action      : Allow
```

---

## 📋 Configuration Quick Reference

### File Locations
```
/etc/danted.conf                    # Main config
/etc/systemd/system/danted-ha.service         # HA service unit
/etc/systemd/system/proxy-watchdog.service    # Watchdog unit
/var/log/proxy-watchdog.log        # Watchdog logs
/var/log/danted.log                # Dante logs
/usr/local/bin/proxy-watchdog.sh   # Watchdog script
/usr/local/bin/proxy-status.sh     # Status script
```

### Key Parameters
```
Port                : 1080
Auth method         : username + none (allow both)
Max connections     : 10,000
Idle timeout        : 10 minutes
Connection timeout  : 30 seconds
Log level          : info
```

### Modify Limits
```bash
# Edit config
sudo nano /etc/danted.conf

# Key settings to adjust
maxchild: 10000              # Increase for high traffic
timeout.io: 600              # Idle timeout (seconds)
timeout.connect: 30          # Connection timeout

# Restart
sudo systemctl restart danted-ha
```

---

## 🧪 Testing Procedures

### Test 1: Local Connectivity
```bash
telnet localhost 1080
# Expected: Connected (or Connection refused if no telnet)

curl --proxy socks5://proxyuser:proxy@123@localhost:1080 https://ifconfig.me
# Expected: Your VM's external IP
```

### Test 2: Remote Connectivity (from client machine)
```bash
curl --proxy socks5://proxyuser:proxy@123@YOUR_VM_IP:1080 https://ifconfig.me
# Expected: Your VM's external IP
```

### Test 3: Crash Recovery
```bash
# Terminal 1 - Watch logs
tail -f /var/log/proxy-watchdog.log

# Terminal 2 - Kill process
sudo kill $(pgrep -x danted)

# Observe: Should auto-restart in <5 seconds
# Check logs: Should show restart action
# Test: proxy-status.sh should show healthy
```

---

## 📞 Need Help?

### Step 1: Check Status
```bash
proxy-status.sh
```

### Step 2: Review Logs
```bash
tail -100 /var/log/proxy-watchdog.log
```

### Step 3: Consult Documentation
- Setup issues → [INSTALLATION.md](INSTALLATION.md)
- Problems → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Questions → [COMPARISON.md](COMPARISON.md)

---

## 🔄 Maintenance Tasks

### Daily
- (None required - fully automated)

### Weekly
```bash
# Check restart frequency
grep "SUCCESS\|restarted" /var/log/proxy-watchdog.log | tail -20

# Review errors
grep "ERROR\|ALERT" /var/log/proxy-watchdog.log | tail -10
```

### Monthly
```bash
# Archive old logs
cp /var/log/proxy-watchdog.log /var/log/proxy-watchdog.$(date +%Y-%m).log
sudo truncate -s 0 /var/log/proxy-watchdog.log

# Check system resources
free -h
df -h
```

---

## 💡 Pro Tips

1. **Monitor via Dashboard**: Use `watch -n 5 'proxy-status.sh'` for real-time monitoring

2. **Automate Testing**: Set up cron job to test proxy periodically

3. **Archive Logs**: Rotate logs monthly to prevent disk fill

4. **Alert Setup**: Configure monitoring system to watch `/var/log/proxy-watchdog.log`

5. **Backup Config**: Keep copies of `/etc/danted.conf` before changes

6. **Performance**: Monitor restart frequency. If >1/hour, check logs for root cause

---

## 📌 Important URLs

| Resource | Purpose |
|----------|---------|
| setup-proxy-ha.sh | Main installer |
| README.md | Overview & features |
| INSTALLATION.md | Setup & configuration |
| TROUBLESHOOTING.md | Diagnosis & fixes |
| COMPARISON.md | Why this is better |

---

## ⏱️ Response Times

| Scenario | Time |
|----------|------|
| Process crash to restart | <5 seconds |
| Watchdog check cycle | 60 seconds |
| Health check detection | <1 minute |
| Full recovery | <5 seconds |

---

## 🎯 Success Indicators

After setup, you should see:

✅ `proxy-status.sh` shows HEALTHY  
✅ `curl` returns VM IP when routed through proxy  
✅ `/var/log/proxy-watchdog.log` shows "Proxy OK" entries  
✅ No manual restarts needed  
✅ Consistent uptime  

If any are missing, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Bookmark This!** Print or save for quick reference 📌

Last Updated: 2026-05-26 | Version: 2.0
