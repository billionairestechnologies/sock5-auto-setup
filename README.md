# 🚀 SOCKS5 Proxy Auto-Setup

> One-command SOCKS5 proxy installer for Ubuntu VMs on Google Cloud Platform (GCP).  
> Built for **Billionaires Technologies** multi-IP broker routing infrastructure.

---

## ⚡ Quick Deploy (One Command)

SSH into your GCP VM and run:

```bash
curl -s https://raw.githubusercontent.com/billionairestechnologies/sock5-auto-setup/main/setup-proxy.sh | sudo bash
```

That's it. Proxy is live in ~60 seconds. ✅

---

## 📋 What It Does

| Step | Action |
|------|--------|
| 1 | Updates system packages |
| 2 | Installs `dante-server`, `nano`, `curl` |
| 3 | Creates `proxyuser` with password |
| 4 | Auto-detects network interface (`ens4` / `eth0`) |
| 5 | Writes optimized Dante SOCKS5 config |
| 6 | Enables **auto-start on VM reboot** via `systemctl enable` |

---

## 🔧 Default Credentials

| Setting | Value |
|---------|-------|
| **Type** | SOCKS5 |
| **Port** | `1080` |
| **Username** | `proxyuser` |
| **Password** | `proxy@123` |

> ⚠️ Change the password in `setup-proxy.sh` before deploying in production.

---

## 🏗️ Architecture

```
OpenAlgo Main Server
        │
        ├── SOCKS5 Proxy VM 1 ──► Static IP 1  ◄── Client Group A
        ├── SOCKS5 Proxy VM 2 ──► Static IP 2  ◄── Client Group B
        ├── SOCKS5 Proxy VM 3 ──► Static IP 3  ◄── Client Group C
        └── SOCKS5 Proxy VM 4 ──► Static IP 4  ◄── Client Group D
```

Each proxy VM has:
- ✅ Its own **static external IP** (attached in GCP)
- ✅ SOCKS5 proxy on port **1080**
- ✅ Auto-restart on VM start/stop

---

## 🌐 GCP Setup Checklist

Before running the script, make sure:

- [ ] VM created (Ubuntu 22.04 recommended, `e2-micro` or `e2-small`)
- [ ] Static IP reserved and attached to VM (`VPC Network → IP Addresses`)
- [ ] Firewall rule created to allow port `1080`

### Firewall Rule (GCP Console)

```
Name        : allow-socks5
Direction   : Ingress
Action      : Allow
Targets     : All instances
Source IP   : 0.0.0.0/0
Port        : tcp:1080
```

---

## 🔄 Deploy on Multiple VMs

For each proxy VM:

1. Open GCP Console → VM Instances → **SSH**
2. Run:
```bash
curl -s https://raw.githubusercontent.com/billionairestechnologies/sock5-auto-setup/main/setup-proxy.sh | sudo bash
```
3. Note the IP + credentials printed at the end ✅

---

## 🧪 Test Your Proxy

### Option 1 — Python
```python
import requests

proxies = {
    "http":  "socks5://proxyuser:proxy@123@YOUR_VM_IP:1080",
    "https": "socks5://proxyuser:proxy@123@YOUR_VM_IP:1080"
}

r = requests.get("https://ifconfig.me", proxies=proxies)
print(r.text)  # Should print your VM's static IP
```

### Option 2 — curl (from your PC)
```bash
curl --proxy socks5://proxyuser:proxy@123@YOUR_VM_IP:1080 https://ifconfig.me
```

### Option 3 — Browser (FoxyProxy Extension)
```
Type     : SOCKS5
Hostname : YOUR_VM_IP
Port     : 1080
Username : proxyuser
Password : proxy@123
```

---

## 🔒 Security Hardening (Optional)

To restrict proxy to **authenticated users only**, edit the config:

```bash
sudo nano /etc/danted.conf
```

Change:
```
socksmethod: username none
```
To:
```
socksmethod: username
```

Then restart:
```bash
sudo systemctl restart danted
```

---

## 📦 Use with OpenAlgo / Python

```python
proxies = {
    "http":  "socks5://proxyuser:proxy@123@IP:1080",
    "https": "socks5://proxyuser:proxy@123@IP:1080"
}

# Pass to your broker API session
session = requests.Session()
session.proxies = proxies
```

---

## 📁 Files

| File | Description |
|------|-------------|
| `setup-proxy.sh` | Main auto-install script |
| `README.md` | This guide |
| `LICENSE` | MIT License |

---

## 🏢 About

Built by **Billionaires Technologies** for scalable multi-client algo trading infrastructure.

- Each client gets a **dedicated static IP** for broker API whitelisting
- Supports **50+ clients** across isolated proxy VMs
- Designed for **OpenAlgo**, **XTS**, and other broker API platforms

---

## 📄 License

MIT License — see [LICENSE](./LICENSE) file.
