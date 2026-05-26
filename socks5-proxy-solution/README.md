# SOCKS5 Proxy Auto-Setup
**Billionaires Technologies** — GCP VPS, no password, auto-restart, watchdog included

---

## One Command Install

SSH into your VPS and paste:

```bash
curl -s https://raw.githubusercontent.com/billionairestechnologies/sock5-auto-setup/main/socks5-proxy-solution/setup-proxy-ha.sh | sudo bash
```

Done. Proxy is live on port **1080**, no password required.

---

## Proxifier Settings

| Field    | Value          |
|----------|----------------|
| Type     | SOCKS5         |
| Address  | `YOUR_VPS_IP`  |
| Port     | `1080`         |
| Auth     | None (no password) |

---

## GCP Firewall — Do This Once

Script cannot open GCP's external firewall. Do it manually:

**GCP Console → VPC Network → Firewall → Create Rule**
- Direction: `Ingress`
- Action: `Allow`
- Source IP: `0.0.0.0/0`
- Protocol/Port: `TCP 1080`

---

## Useful Commands After Install

```bash
# Check proxy is running
ss -tuln | grep 1080

# Service status
sudo systemctl status danted-ha

# Restart proxy
sudo systemctl restart danted-ha

# Live logs
sudo journalctl -u danted-ha -f

# Watchdog logs
tail -f /var/log/proxy-watchdog.log

# Full health check
proxy-status.sh
```

---

## What Gets Installed

| Component           | Purpose                           |
|---------------------|-----------------------------------|
| `dante-server`      | SOCKS5 proxy daemon               |
| `danted-ha.service` | Systemd service, auto-restarts    |
| `proxy-watchdog.sh` | Health check every 60s            |
| `proxy-status.sh`   | Quick status check command        |

---

## Uninstall

```bash
sudo systemctl stop danted-ha proxy-watchdog
sudo systemctl disable danted-ha proxy-watchdog
sudo apt remove dante-server -y
sudo rm -f /etc/danted.conf /etc/systemd/system/danted-ha.service /etc/systemd/system/proxy-watchdog.service
sudo rm -f /usr/local/bin/proxy-watchdog.sh /usr/local/bin/proxy-status.sh
sudo systemctl daemon-reload
```


