# Monitoring Commands Reference

## Overview
This reference guide provides all the commands you need to monitor and troubleshoot your Wombat Workouts deployment on Hetzner using Kamal 2.

**Quick Access:** All commands should be run from the `/Users/jamie/code/fitorforget` directory unless otherwise specified.

---

## Application Monitoring

### Check Container Status

View detailed information about running application containers:

```bash
kamal app details
```

**What it shows:**
- Container ID and name
- Docker image and tag currently deployed
- Container status (Up/Down and duration)
- Port mappings (internal and external)
- Volume mounts
- Health check configuration
- Restart policy
- Environment variables (secrets masked)

**Example output:**
```
App Host: 123.456.789.012
CONTAINER ID   IMAGE                                           STATUS         PORTS
abc123def456   ghcr.io/ideasasylum/wombatworkouts:v123        Up 5 hours     80/tcp
```

**When to use:**
- Check if application is running
- Verify correct image version deployed
- Confirm container hasn't restarted unexpectedly
- View uptime and health status

### View Application Logs (Real-Time)

Stream live application logs:

```bash
kamal app logs -f
```

**Alias:** `kamal logs` (configured in deploy.yml)

**What it shows:**
- Rails application logs (info, debug, error)
- Puma web server requests and responses
- Solid Queue job processing (if jobs running)
- SQL queries (if RAILS_LOG_LEVEL=debug)
- Stack traces for errors
- Health check pings

**Keyboard shortcuts:**
- `Ctrl+C` - Stop streaming and exit
- Logs scroll continuously until stopped

**Filtering options:**
```bash
# Show last 100 lines
kamal app logs --tail 100

# Show logs from last hour
kamal app logs --since 1h

# Show logs from last 24 hours
kamal app logs --since 24h

# Show logs since specific time
kamal app logs --since "2024-11-04T10:00:00"
```

**When to use:**
- Troubleshooting errors
- Monitoring request patterns
- Debugging performance issues
- Watching deployment progress
- Investigating user-reported issues

### View Application Version

Check which version is currently deployed:

```bash
kamal app details | grep IMAGE
```

**Example output:**
```
IMAGE: ghcr.io/ideasasylum/wombatworkouts:v123
```

**Or get just the tag:**
```bash
kamal app exec 'echo $KAMAL_VERSION'
```

### Check Application Health

Test the health check endpoint:

```bash
# Via Kamal (inside container)
kamal app exec 'curl -f http://localhost:80/up'

# Via public URL
curl -i https://wombatworkouts.com/up
```

**Expected response:**
```
HTTP/2 200
content-type: text/html; charset=utf-8

<!DOCTYPE html>
<html>...
```

**When to use:**
- Verify application is responding
- Check after deployment
- Troubleshoot 502/503 errors
- Validate before switching traffic

### Restart Application

Restart the application container without redeploying:

```bash
kamal app restart
```

**What it does:**
- Stops current container
- Starts new container with same image
- Runs docker-entrypoint (db:prepare)
- Waits for health checks to pass

**When to use:**
- Clear stuck processes
- Apply environment variable changes
- Troubleshoot hung requests
- Reset application state

**Note:** Does NOT pull new code - use `kamal deploy` for that.

---

## Process Monitoring

### View Running Processes

See all processes inside the application container:

```bash
kamal app exec 'ps aux'
```

**What to look for:**
- **Puma master process** - Should always be running
- **Puma worker processes** - Number based on WEB_CONCURRENCY
- **Solid Queue supervisor** - If SOLID_QUEUE_IN_PUMA enabled
- **Rails processes** - For active requests

**Example output:**
```
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
rails        1  0.1  2.3  623804 186532 ?      Ssl  10:00   0:15 puma 6.4.0 (tcp://0.0.0.0:80) [app]
rails       23  0.2  2.1  624328 185940 ?      Sl   10:00   0:20 puma: cluster worker 0: 1
rails       24  0.2  2.1  624328 185940 ?      Sl   10:00   0:20 puma: cluster worker 1: 1
```

**Monitoring tips:**
- High CPU% - Possible performance issue or heavy request
- High MEM% - Check for memory leak
- Multiple similar processes - Normal for Puma workers
- Zombie processes - Application might be stuck

### Sort Processes by CPU Usage

Find CPU-intensive processes:

```bash
kamal app exec 'ps aux --sort=-%cpu | head -n 10'
```

**When to use:**
- High server CPU usage
- Slow response times
- Identify expensive operations

### Sort Processes by Memory Usage

Find memory-intensive processes:

```bash
kamal app exec 'ps aux --sort=-%mem | head -n 10'
```

**When to use:**
- High memory usage alerts
- Out of memory errors
- Memory leak investigation

### Count Active Puma Workers

```bash
kamal app exec 'ps aux | grep puma | grep worker | wc -l'
```

**Expected:** Should match WEB_CONCURRENCY setting (default: based on CPU cores)

---

## System Resource Monitoring

### Check Memory Usage

View container memory consumption:

```bash
kamal app exec 'free -h'
```

**Example output:**
```
              total        used        free      shared  buff/cache   available
Mem:           62Gi       1.2Gi       58Gi       42Mi       2.8Gi       60Gi
Swap:            0B          0B          0B
```

**What to monitor:**
- **used** - Should be stable over time
- **available** - Should have plenty free
- **Swap** - Should be 0 (no swap configured)

**Warning signs:**
- Memory usage growing over time (memory leak)
- Available memory < 20% (risk of OOM)
- Swap usage > 0 (performance degradation)

### Check Disk Usage

View disk space on container filesystem:

```bash
kamal app exec 'df -h'
```

**Example output:**
```
Filesystem      Size  Used Avail Use% Mounted on
overlay         450G   12G  415G   3% /
tmpfs            31G     0   31G   0% /dev
/dev/sda1       450G   12G  415G   3% /rails/storage
```

**What to monitor:**
- **/** - Root filesystem (should be < 80%)
- **/rails/storage** - SQLite databases (should be < 80%)

**Warning signs:**
- Use% > 80% - Running out of disk space
- Rapid growth - Check log files or database size

### Check Database File Sizes

View size of SQLite database files:

```bash
kamal app exec 'ls -lh storage/'
```

**Example output:**
```
total 120M
-rw-r--r-- 1 rails rails  80M Nov  4 10:00 production.sqlite3
-rw-r--r-- 1 rails rails  15M Nov  4 10:00 production_cache.sqlite3
-rw-r--r-- 1 rails rails  20M Nov  4 10:00 production_queue.sqlite3
-rw-r--r-- 1 rails rails  5M  Nov  4 10:00 production_cable.sqlite3
```

**Monitoring tips:**
- Track growth over time
- production.sqlite3 usually largest
- Rapid growth may indicate data accumulation issue
- Consider cleanup strategies if too large

### Check Disk I/O

View disk I/O statistics:

```bash
kamal app exec 'iostat -x 1 5'
```

**What to monitor:**
- **%util** - Disk utilization (should be < 80%)
- **await** - Average wait time (should be < 10ms)

**Note:** May need to install sysstat package if iostat not available.

### Real-Time Resource Monitoring

Watch container resource usage in real-time:

```bash
# From server (SSH required)
ssh root@<server-ip>
docker stats $(docker ps -q -f name=wombatworkouts-web)
```

**What it shows:**
- CPU% - Real-time CPU usage
- MEM USAGE / LIMIT - Memory consumption
- MEM% - Memory percentage
- NET I/O - Network traffic
- BLOCK I/O - Disk I/O

**Keyboard shortcuts:**
- `Ctrl+C` - Exit monitoring

---

## Proxy Monitoring

### Check Traefik Status

View Traefik reverse proxy details:

```bash
kamal proxy details
```

**What it shows:**
- Traefik container status and uptime
- Registered routers (applications)
- Hostname rules and routing configuration
- SSL/TLS certificate status
- Backend services (application containers)
- Entry points (ports 80, 443)

**Example output:**
```
Traefik Host: 123.456.789.012
CONTAINER ID   IMAGE           STATUS       PORTS
xyz789         traefik:v2.9    Up 10 hours  80/tcp, 443/tcp

Routers:
  wombatworkouts: wombatworkouts.com → wombatworkouts-web-abc123
```

**When to use:**
- Verify SSL certificates active
- Check routing configuration
- Troubleshoot proxy issues
- Confirm new apps registered

### View Proxy Logs

Stream Traefik proxy logs:

```bash
kamal proxy logs -f
```

**What it shows:**
- HTTP/HTTPS requests being proxied
- SSL/TLS handshake messages
- Let's Encrypt certificate operations
- Backend health check results
- Routing decisions
- Error responses (502, 503, etc.)

**Filtering options:**
```bash
# Last 100 lines
kamal proxy logs --tail 100

# Last hour
kamal proxy logs --since 1h
```

**When to use:**
- Troubleshooting SSL issues
- Investigating certificate renewals
- Debugging routing problems
- Monitoring request patterns

### Check SSL Certificate Status

View Let's Encrypt certificates:

```bash
kamal proxy logs | grep -i "certificate"
```

**Or check via browser:**
1. Visit https://wombatworkouts.com
2. Click padlock icon
3. View certificate details
4. Check expiration date (should be ~90 days out)

**Certificate lifecycle:**
- **Issued:** When first deployed
- **Valid for:** 90 days
- **Auto-renewed:** Every 60 days
- **Issuer:** Let's Encrypt

### Test Proxy Response Time

Measure proxy overhead:

```bash
curl -w "@-" -o /dev/null -s https://wombatworkouts.com << 'EOF'
time_namelookup:  %{time_namelookup}\n
time_connect:     %{time_connect}\n
time_appconnect:  %{time_appconnect}\n
time_pretransfer: %{time_pretransfer}\n
time_starttransfer: %{time_starttransfer}\n
time_total:       %{time_total}\n
EOF
```

**What to monitor:**
- time_total - Complete request time (should be < 500ms for /up)
- time_appconnect - SSL handshake (should be < 100ms)

---

## Backup Monitoring

### Check Litestream Status

View Litestream backup accessory status:

```bash
kamal accessory details litestream
```

**What it shows:**
- Litestream container status
- Volume mounts (should show wombatworkouts_storage)
- Configuration file mount (/etc/litestream.yml)
- Environment variables (credentials masked)
- Container uptime

**Example output:**
```
Accessory Host: 123.456.789.012
CONTAINER ID   IMAGE                      STATUS       VOLUMES
lmn456         litestream/litestream      Up 2 hours   wombatworkouts_storage:/data
```

**When to use:**
- Verify backups are running
- Check after deployment
- Troubleshoot backup issues
- Confirm configuration loaded

### View Backup Replication Logs

Stream Litestream backup logs:

```bash
kamal accessory logs litestream -f
```

**What it shows:**
- Replication status messages
- Snapshot creation events
- Upload confirmations to S3
- WAL segment uploads
- Error messages (if any)

**Example healthy output:**
```
time=2024-11-04T10:15:00Z level=INFO msg="replicating to s3" db=/data/storage/production.sqlite3
time=2024-11-04T10:15:05Z level=INFO msg="snapshot written" db=/data/storage/production.sqlite3 size=80MB
```

**Filtering options:**
```bash
# Last 100 lines
kamal accessory logs litestream --tail 100

# Last 24 hours
kamal accessory logs litestream --since 24h
```

**When to use:**
- Verify backups uploading successfully
- Check backup frequency
- Troubleshoot S3 connection issues
- Monitor backup size growth

### Check Last Backup Time

Find most recent backup for each database:

```bash
# SSH to server
ssh root@<server-ip>

# Check production database
docker exec -it $(docker ps -q -f name=litestream) \
  litestream generations -config /etc/litestream.yml /data/storage/production.sqlite3
```

**What to look for:**
- **lag** - Time since last backup (should be < 1 minute)
- **end** - Timestamp of most recent backup

**Warning signs:**
- lag > 5 minutes - Replication may be stuck
- No recent backups - Check Litestream logs

### Verify All Databases Backing Up

Check replication status for all 4 databases:

```bash
ssh root@<server-ip>

# Loop through all databases
for db in production production_cache production_queue production_cable; do
  echo "=== ${db}.sqlite3 ==="
  docker exec -it $(docker ps -q -f name=litestream) \
    litestream generations -config /etc/litestream.yml /data/storage/${db}.sqlite3 | tail -n 1
done
```

**Expected:** Recent entries for all 4 databases

---

## Network Monitoring

### Check Network Connections

View active network connections:

```bash
kamal app exec 'netstat -tnp'
```

**What to monitor:**
- Number of ESTABLISHED connections
- Many TIME_WAIT (normal after requests)
- CLOSE_WAIT accumulating (possible leak)

### Test DNS Resolution

Verify domain resolves correctly:

```bash
dig wombatworkouts.com
```

**Expected output:**
```
wombatworkouts.com.  300  IN  A  123.456.789.012
```

**When to use:**
- After DNS changes
- SSL certificate not generating
- Domain not accessible

### Check Network Latency

Test latency to server:

```bash
ping -c 5 <server-ip>
```

**What to monitor:**
- Average ping time (should be < 100ms from nearby)
- Packet loss (should be 0%)

---

## Database Monitoring

### Check Database Connections

Count active database connections:

```bash
kamal app exec 'lsof -n | grep production.sqlite3 | wc -l'
```

**Note:** SQLite has limited concurrent connections.

### Run Database Integrity Check

Verify database not corrupted:

```bash
kamal app exec 'sqlite3 storage/production.sqlite3 "PRAGMA integrity_check;"'
```

**Expected output:** `ok`

**When to use:**
- After unexpected crashes
- Before major migrations
- Troubleshooting data issues

### Check Migration Status

View which migrations have run:

```bash
kamal app exec 'bin/rails db:migrate:status'
```

**Example output:**
```
up     20240101000001  Create users
up     20240102000002  Create workouts
up     20240103000003  Add fields to workouts
```

**When to use:**
- Verify migrations ran on deployment
- Troubleshoot migration issues
- Check production vs. local schema sync

### View Database Schema Version

```bash
kamal app exec 'bin/rails runner "puts ActiveRecord::Migrator.current_version"'
```

---

## Performance Monitoring

### Measure Request Response Time

Test endpoint response time:

```bash
time curl -s https://wombatworkouts.com/up > /dev/null
```

**Expected:** < 500ms for health check

### Load Testing (Simple)

Send multiple requests:

```bash
# 100 requests, 10 concurrent
ab -n 100 -c 10 https://wombatworkouts.com/up
```

**What to monitor:**
- Requests per second
- Average response time
- Failed requests (should be 0)

**Note:** Don't overload production - use sparingly!

---

## Comprehensive System Check

### Quick Health Check Script

Run all essential checks at once:

```bash
# Application status
echo "=== Application Status ==="
kamal app details

# Recent errors in logs
echo -e "\n=== Recent Errors ==="
kamal app logs --since 1h | grep -i error | tail -n 10

# Memory usage
echo -e "\n=== Memory Usage ==="
kamal app exec 'free -h'

# Disk usage
echo -e "\n=== Disk Usage ==="
kamal app exec 'df -h | grep -E "(Filesystem|/rails)"'

# Database sizes
echo -e "\n=== Database Sizes ==="
kamal app exec 'ls -lh storage/*.sqlite3'

# Proxy status
echo -e "\n=== Proxy Status ==="
kamal proxy details

# Backup status
echo -e "\n=== Backup Status ==="
kamal accessory details litestream

# Health endpoint
echo -e "\n=== Health Endpoint ==="
curl -s -o /dev/null -w "Status: %{http_code}\nTime: %{time_total}s\n" https://wombatworkouts.com/up
```

---

## Alerting Thresholds

### What to Monitor and When to Alert

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| Disk usage | > 70% | > 85% | Clear logs/data |
| Memory usage | > 80% | > 95% | Restart or upgrade |
| CPU sustained | > 80% 5min | > 95% 5min | Investigate/scale |
| Health check | 1 failure | 3 failures | Check logs |
| Backup lag | > 5min | > 30min | Restart Litestream |
| Response time | > 1s | > 5s | Investigate |

---

## Monitoring Schedule

### Daily Checks (5 minutes)

```bash
# Quick status
kamal app details
kamal accessory logs litestream --tail 10

# Check for errors
kamal app logs --since 24h | grep -i error

# Test health
curl https://wombatworkouts.com/up
```

### Weekly Checks (15 minutes)

```bash
# Full system check (script above)
# Review disk usage trends
# Check database growth
# Review backup logs
# Test restore on local machine
```

### Monthly Checks (30 minutes)

```bash
# Full backup restore test
# Review Traefik access patterns
# Check SSL certificate expiration
# Review resource usage trends
# Plan capacity if needed
```

---

## Troubleshooting Quick Reference

### High CPU Usage

```bash
kamal app exec 'ps aux --sort=-%cpu | head -n 10'
kamal app logs --since 1h | grep -i slow
```

### High Memory Usage

```bash
kamal app exec 'free -h'
kamal app exec 'ps aux --sort=-%mem | head -n 10'
# Consider restart: kamal app restart
```

### Disk Space Low

```bash
kamal app exec 'df -h'
kamal app exec 'du -h storage/ | sort -h | tail -n 10'
# Consider cleanup or expansion
```

### Application Not Responding

```bash
kamal app details  # Check if running
kamal app logs --tail 50  # Check for errors
kamal proxy logs --tail 50  # Check proxy
curl https://wombatworkouts.com/up  # Test directly
```

### Backups Not Running

```bash
kamal accessory details litestream  # Check running
kamal accessory logs litestream --tail 50  # Check errors
# Restart: kamal accessory restart litestream
```

---

**Last Updated:** 2025-11-04
**Kamal Version:** 2.x
**Server:** Hetzner AX41-NVMe
**Monitoring Tools:** Kamal built-in, curl, Docker stats
