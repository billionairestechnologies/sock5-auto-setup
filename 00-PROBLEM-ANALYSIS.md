# SOCKS5 Proxy Offline Issue - Root Cause Analysis

## Problem Statement
- Proxy works initially after install
- IP routing functions correctly
- After some time (~hours/days), proxy goes offline
- Must restart/reinstall to fix
- No error messages in logs

## Root Causes Identified

### 1. **No Crash Recovery Mechanism**
- Current setup only uses `systemctl enable` (boots on VM restart)
- If `danted` process crashes during runtime, NOTHING restarts it
- Proxy becomes unreachable but service appears "enabled"

### 2. **Resource Exhaustion**
- Dante can accumulate idle connections
- File descriptor limits not configured
- Memory leaks possible in long-running processes
- No connection pooling or cleanup

### 3. **Silent Failures**
- Logging only to syslog (may be lost)
- No active health checks
- No alerting mechanism
- No monitoring dashboard

### 4. **Missing Service Hardening**
- No systemd auto-restart policies
- No startup delays for recovery
- No resource limits configured

## Solution Components

1. **Enhanced danted.conf** - Add resource limits, timeouts, better logging
2. **Systemd Service Hardening** - Auto-restart on failure with backoff
3. **Health Check Watchdog** - Monitor proxy every 60 seconds, restart if down
4. **Status Dashboard** - Simple script to check proxy health
5. **Centralized Logging** - Pipe to file + monitoring
6. **Installation Script** - One-command full deployment

## Expected Results
✅ Automatic crash recovery
✅ Real-time health monitoring  
✅ Zero-downtime failover
✅ Persistent logging
✅ Status visibility
