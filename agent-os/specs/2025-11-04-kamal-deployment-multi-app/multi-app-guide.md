# Multi-App Setup Guide

## Overview
This guide explains how to deploy multiple Rails applications to the same Hetzner server, sharing the Traefik reverse proxy while maintaining complete isolation between applications.

The Wombat Workouts deployment has already set up the Traefik proxy infrastructure. Future Rails applications can be added to the same server by following the patterns documented here.

---

## Architecture Overview

### How Multi-App Works

**Shared Components:**
- **Traefik Proxy:** Single Traefik container handles all incoming HTTP/HTTPS traffic
- **Docker Network:** All app containers connect to same Docker network
- **Let's Encrypt:** Traefik manages SSL certificates for all domains
- **Server Resources:** Apps share CPU, RAM, and disk on Hetzner server

**Isolated Components:**
- **Docker Volumes:** Each app has its own named volume for data persistence
- **Service Names:** Each app has unique Kamal service name
- **Containers:** Each app runs in separate Docker container(s)
- **Databases:** Each app has its own SQLite databases
- **Litestream:** Each app can have its own backup accessory

### Current Setup

**Existing Application:**
- **Service:** wombatworkouts
- **Domain:** wombatworkouts.com
- **Volume:** wombatworkouts_storage
- **Traefik Labels:** Routes wombatworkouts.com traffic to this service
- **Proxy:** Shared Traefik proxy on port 80/443

---

## Adding a New Rails Application

### Step 1: Prepare Your Rails Application

Ensure your Rails app has:

1. **Dockerfile** - Production-ready Dockerfile
2. **docker-entrypoint** - Script to run database migrations
3. **Health endpoint** - /up or custom health check route
4. **SQLite databases** - Configure for SQLite in production
5. **Kamal installed** - Add kamal gem to Gemfile

Example health endpoint in `config/routes.rb`:
```ruby
get "up" => "rails/health#show", as: :rails_health_check
```

### Step 2: Create Kamal Configuration

Create `config/deploy.yml` in your new Rails app:

```yaml
# Name of your application - MUST BE UNIQUE per app
service: myapp

# Container image name - use your GitHub username
image: ideasasylum/myapp

# Same Hetzner server (multiple apps share same server)
servers:
  web:
    - REPLACE_WITH_YOUR_HETZNER_SERVER_IP

# Proxy configuration - same as wombatworkouts
proxy:
  ssl: true
  host: myapp.com  # YOUR NEW DOMAIN
  app_port: 80

# Traefik labels - CRITICAL for multi-app routing
labels:
  traefik.http.routers.myapp.rule: Host(`myapp.com`)  # YOUR DOMAIN
  traefik.http.routers.myapp.entrypoints: websecure
  traefik.http.routers.myapp.tls.certresolver: letsencrypt

# Health check configuration
healthcheck:
  path: /up
  port: 80
  max_attempts: 7
  interval: 10s

# GitHub Container Registry (same as wombatworkouts)
registry:
  server: ghcr.io
  username: ideasasylum
  password:
    - KAMAL_REGISTRY_PASSWORD

# Environment variables
env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    SOLID_QUEUE_IN_PUMA: true

# Aliases for convenience
aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
  dbc: app exec --interactive --reuse "bin/rails dbconsole --include-password"

# UNIQUE volume name per app - CRITICAL for isolation
volumes:
  - "myapp_storage:/rails/storage"

# Asset bridging for zero-downtime deploys
asset_path: /rails/public/assets

# Builder configuration
builder:
  arch: amd64

# Optional: Litestream for this app's databases
accessories:
  litestream:
    image: litestream/litestream:latest
    host: REPLACE_WITH_YOUR_HETZNER_SERVER_IP
    volumes:
      - "myapp_storage:/data"
      - "/etc/litestream-myapp.yml:/etc/litestream.yml"
    cmd: replicate
    env:
      secret:
        - LITESTREAM_ACCESS_KEY_ID
        - LITESTREAM_SECRET_ACCESS_KEY
```

### Step 3: Configure DNS

Add DNS records for your new domain:

1. **A Record:** myapp.com → Hetzner server IP
2. **Wait for propagation:** 5-10 minutes
3. **Verify resolution:** `dig myapp.com`

### Step 4: Configure Secrets

Create `.kamal/secrets` in your new Rails app:

```bash
#!/bin/bash

# GitHub Container Registry token (same for all apps)
KAMAL_REGISTRY_PASSWORD=$(gh auth token)

# Rails master key (unique per app)
RAILS_MASTER_KEY=$(cat config/master.key)

# Litestream credentials (can share same bucket or use different one)
LITESTREAM_ACCESS_KEY_ID=your_access_key_here
LITESTREAM_SECRET_ACCESS_KEY=your_secret_key_here
```

**Important:** Never commit `.kamal/secrets` or `config/master.key` to git!

### Step 5: Create Litestream Configuration (Optional)

If using Litestream backups, create `litestream-myapp.yml`:

```yaml
dbs:
  - path: /data/storage/production.sqlite3
    replicas:
      - url: s3://myapp-backups/production.sqlite3

  - path: /data/storage/production_cable.sqlite3
    replicas:
      - url: s3://myapp-backups/production_cable.sqlite3

  - path: /data/storage/production_cache.sqlite3
    replicas:
      - url: s3://myapp-backups/production_cache.sqlite3

  - path: /data/storage/production_queue.sqlite3
    replicas:
      - url: s3://myapp-backups/production_queue.sqlite3
```

Upload to server:
```bash
scp litestream-myapp.yml root@<server-ip>:/etc/litestream-myapp.yml
```

### Step 6: Deploy the New Application

From your new Rails app directory:

```bash
# First-time setup (creates containers and volumes)
kamal setup

# Regular deployments
kamal deploy
```

**What happens:**
1. Kamal connects to the SAME Hetzner server
2. Uses the EXISTING Traefik proxy (doesn't create new one)
3. Creates NEW Docker volume with unique name
4. Starts NEW container for your app
5. Registers app with Traefik using your labels
6. Traefik automatically gets Let's Encrypt certificate
7. Routes traffic based on hostname

### Step 7: Verify Multi-App Setup

Check both apps are running:

```bash
# From wombatworkouts directory
kamal app details

# From myapp directory
kamal app details

# Check Traefik sees both apps
kamal proxy details
```

Test both domains:
- https://wombatworkouts.com - Should serve Wombat Workouts
- https://myapp.com - Should serve your new app

---

## Traefik Label Patterns

### Host-Based Routing (Different Domains)

**Pattern:** Route traffic based on domain name

**Wombat Workouts (existing):**
```yaml
labels:
  traefik.http.routers.wombatworkouts.rule: Host(`wombatworkouts.com`)
  traefik.http.routers.wombatworkouts.entrypoints: websecure
  traefik.http.routers.wombatworkouts.tls.certresolver: letsencrypt
```

**New App:**
```yaml
labels:
  traefik.http.routers.myapp.rule: Host(`myapp.com`)
  traefik.http.routers.myapp.entrypoints: websecure
  traefik.http.routers.myapp.tls.certresolver: letsencrypt
```

**How it works:**
- Traefik checks incoming request's Host header
- Routes wombatworkouts.com → wombatworkouts container
- Routes myapp.com → myapp container
- Each domain gets its own SSL certificate

### Path-Based Routing (Same Domain, Different Paths)

**Pattern:** Route traffic based on URL path

**Example:** Host multiple apps under wombatworkouts.com

**Main App (root path):**
```yaml
labels:
  traefik.http.routers.wombatworkouts.rule: Host(`wombatworkouts.com`) && PathPrefix(`/`)
  traefik.http.routers.wombatworkouts.priority: 1
  traefik.http.routers.wombatworkouts.entrypoints: websecure
  traefik.http.routers.wombatworkouts.tls.certresolver: letsencrypt
```

**API App (api path):**
```yaml
labels:
  traefik.http.routers.api.rule: Host(`wombatworkouts.com`) && PathPrefix(`/api`)
  traefik.http.routers.api.priority: 10
  traefik.http.routers.api.entrypoints: websecure
  traefik.http.routers.api.tls.certresolver: letsencrypt
  traefik.http.middlewares.api-stripprefix.stripprefix.prefixes: /api
  traefik.http.routers.api.middlewares: api-stripprefix
```

**How it works:**
- wombatworkouts.com/ → main app
- wombatworkouts.com/api/ → api app (with /api stripped)
- Higher priority number = evaluated first
- Single SSL certificate shared

### Subdomain Routing

**Pattern:** Route traffic based on subdomain

**Main App:**
```yaml
labels:
  traefik.http.routers.wombatworkouts.rule: Host(`wombatworkouts.com`)
  traefik.http.routers.wombatworkouts.entrypoints: websecure
  traefik.http.routers.wombatworkouts.tls.certresolver: letsencrypt
```

**Admin App:**
```yaml
labels:
  traefik.http.routers.admin.rule: Host(`admin.wombatworkouts.com`)
  traefik.http.routers.admin.entrypoints: websecure
  traefik.http.routers.admin.tls.certresolver: letsencrypt
```

**How it works:**
- wombatworkouts.com → main app
- admin.wombatworkouts.com → admin app
- Each subdomain gets its own SSL certificate
- Need DNS A records for each subdomain

---

## Volume Isolation Strategy

### Why Volume Isolation Matters

Each Rails app needs its own Docker volume to prevent:
- Database file conflicts
- Data corruption
- Accidental data sharing
- Backup confusion

### Naming Convention

**Pattern:** `<service-name>_storage`

**Examples:**
- Wombat Workouts: `wombatworkouts_storage`
- My App: `myapp_storage`
- Admin Panel: `adminpanel_storage`
- API Service: `apiservice_storage`

### Volume Configuration

**In deploy.yml:**
```yaml
volumes:
  - "myapp_storage:/rails/storage"
```

**What this does:**
- Creates Docker volume named `myapp_storage`
- Mounts to `/rails/storage` inside container
- Persists SQLite databases across deployments
- Isolated from other apps' volumes

### Checking Volumes on Server

SSH to server and list volumes:
```bash
ssh root@<server-ip>
docker volume ls
```

**Expected output:**
```
DRIVER    VOLUME NAME
local     wombatworkouts_storage
local     myapp_storage
local     adminpanel_storage
```

### Backing Up Volumes

Each app can use Litestream with its own configuration:
- Separate litestream.yml files on server
- Different S3 bucket or different paths in same bucket
- Independent backup schedules
- No backup collisions

---

## Service Naming Conventions

### Service Name Rules

**Requirements:**
- Must be unique per application
- Used for container naming
- Used for Traefik router naming
- Should be lowercase, no spaces
- Alphanumeric and hyphens only

**Pattern:** `<app-name>`

**Examples:**
- `wombatworkouts` - Main workout app
- `myapp` - Generic app name
- `fitness-tracker` - With hyphen
- `nutrition-log` - Another example
- `workout-api` - API-specific service

### Service Name Usage

Service name appears in:

1. **deploy.yml:**
   ```yaml
   service: myapp
   ```

2. **Container names on server:**
   ```
   myapp-web-abc123
   ```

3. **Traefik router names:**
   ```yaml
   traefik.http.routers.myapp.rule: Host(`myapp.com`)
   ```

4. **Docker volume names:**
   ```
   myapp_storage
   ```

5. **Kamal commands:**
   ```bash
   kamal myapp deploy
   kamal myapp logs
   ```

### Checking Service Names

List all Kamal services on server:
```bash
ssh root@<server-ip>
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Expected output:**
```
NAMES                          STATUS          PORTS
wombatworkouts-web-abc123     Up 2 hours      80/tcp
myapp-web-def456              Up 1 hour       80/tcp
traefik                       Up 3 hours      80/tcp, 443/tcp
```

---

## Step-by-Step Example: Adding a Second App

Let's walk through adding "Nutrition Log" app to the same server.

### 1. Prepare Rails App

```bash
# In your nutrition-log Rails app directory
cd ~/code/nutrition-log

# Ensure Kamal is installed
bundle add kamal

# Initialize Kamal
kamal init
```

### 2. Create deploy.yml

```yaml
service: nutrition-log
image: ideasasylum/nutrition-log

servers:
  web:
    - 123.456.789.012  # Same IP as wombatworkouts

proxy:
  ssl: true
  host: nutritionlog.com  # Your new domain
  app_port: 80

labels:
  traefik.http.routers.nutritionlog.rule: Host(`nutritionlog.com`)
  traefik.http.routers.nutritionlog.entrypoints: websecure
  traefik.http.routers.nutritionlog.tls.certresolver: letsencrypt

healthcheck:
  path: /up
  port: 80
  max_attempts: 7
  interval: 10s

registry:
  server: ghcr.io
  username: ideasasylum
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    SOLID_QUEUE_IN_PUMA: true

volumes:
  - "nutritionlog_storage:/rails/storage"

asset_path: /rails/public/assets

builder:
  arch: amd64
```

### 3. Configure DNS

```bash
# Add DNS A record
nutritionlog.com → 123.456.789.012

# Verify after propagation
dig nutritionlog.com
```

### 4. Create Secrets

```bash
# Edit .kamal/secrets
chmod +x .kamal/secrets
```

```bash
#!/bin/bash
KAMAL_REGISTRY_PASSWORD=$(gh auth token)
RAILS_MASTER_KEY=$(cat config/master.key)
```

### 5. Deploy

```bash
# First deployment
kamal setup

# Watch logs
kamal logs -f
```

### 6. Verify Both Apps

```bash
# Check wombatworkouts (from wombatworkouts directory)
cd ~/code/fitorforget
kamal app details

# Check nutrition-log (from nutrition-log directory)
cd ~/code/nutrition-log
kamal app details

# Check Traefik sees both
kamal proxy details
```

### 7. Test Both Domains

```bash
# Test wombatworkouts
curl -I https://wombatworkouts.com

# Test nutrition-log
curl -I https://nutritionlog.com
```

Both should return 200 OK with valid SSL certificates!

---

## Resource Considerations

### Server Capacity

**Hetzner AX41-NVMe:**
- 6 CPU cores
- 64GB RAM
- Plenty of disk space

**Realistic capacity:**
- 5-10 small Rails apps (low traffic)
- 2-3 medium Rails apps (moderate traffic)
- 1-2 large Rails apps (high traffic)

### Memory Per App

**Typical Rails app memory usage:**
- Base Rails app: 200-500MB
- With Puma workers: 500MB-1GB
- With Solid Queue: +200-500MB
- With Action Cable: +100-300MB

**Monitor memory:**
```bash
# From each app directory
kamal app exec 'free -h'
kamal app exec 'ps aux --sort=-%mem | head -n 10'
```

### CPU Usage

Rails apps typically use:
- 0.5-1 core idle
- 1-2 cores under load
- Spikes during deployments

**Monitor CPU:**
```bash
kamal app exec 'ps aux --sort=-%cpu | head -n 10'
```

### Disk Usage

Watch disk space per app:
```bash
# Database sizes
kamal app exec 'du -h storage/'

# Total volume usage
ssh root@<server-ip>
docker system df -v
```

---

## Troubleshooting Multi-App Setup

### App Not Receiving Traffic

**Symptoms:** Domain times out or shows 404

**Checks:**
1. Verify DNS points to server:
   ```bash
   dig myapp.com
   ```

2. Check Traefik sees the app:
   ```bash
   kamal proxy details
   ```

3. Verify Traefik labels in deploy.yml match domain

4. Check Traefik logs:
   ```bash
   kamal proxy logs --tail 50
   ```

### SSL Certificate Not Generated

**Symptoms:** Browser shows "Not Secure" or certificate error

**Checks:**
1. Verify DNS resolves (Let's Encrypt requires this)
2. Check Traefik logs for Let's Encrypt errors
3. Verify `tls.certresolver: letsencrypt` in labels
4. Check rate limits (50 certs/week per domain)

### Apps Conflicting

**Symptoms:** One app serving another app's content

**Checks:**
1. Verify unique service names in each deploy.yml
2. Verify unique Traefik router names in labels
3. Check for overlapping routing rules
4. Ensure correct Host() rules in labels

### Volume Access Issues

**Symptoms:** Database errors, missing files

**Checks:**
1. Verify unique volume names per app
2. Check volume exists on server:
   ```bash
   docker volume ls
   ```
3. Verify volume mount path in deploy.yml
4. Check volume permissions

---

## Best Practices

### When Adding New Apps

1. Always use unique service names
2. Always use unique volume names
3. Always use unique Traefik router names
4. Test DNS before deploying
5. Start with minimal configuration
6. Add Litestream after app is stable
7. Monitor resource usage
8. Document each app's domain and purpose

### Security

1. Keep secrets isolated per app
2. Don't share master keys between apps
3. Use separate S3 buckets for backups
4. Review Traefik access logs regularly
5. Limit SSH access to production server

### Maintenance

1. Update one app at a time
2. Monitor all apps after deploying one
3. Keep Traefik proxy updated
4. Restart proxy only when necessary
5. Test rollback on each app periodically

---

## Quick Reference

### Key Differences Per App

| Component | Must Be Unique | Can Be Shared |
|-----------|---------------|---------------|
| Service name | YES | - |
| Domain/subdomain | YES | - |
| Docker volume | YES | - |
| Traefik router name | YES | - |
| Traefik labels | YES | - |
| Server IP | - | YES |
| Traefik proxy | - | YES |
| GitHub registry | - | YES |
| S3 bucket | RECOMMENDED | Can share |
| Litestream config | YES | - |

### Configuration Checklist

When adding a new app, ensure:
- [ ] Unique service name in deploy.yml
- [ ] Unique volume name in deploy.yml
- [ ] Unique Traefik router name in labels
- [ ] Correct domain in proxy.host
- [ ] Correct domain in Traefik Host() rule
- [ ] DNS A record created and propagated
- [ ] .kamal/secrets configured
- [ ] Unique Litestream config file (if using)

---

**Last Updated:** 2025-11-04
**Server Capacity:** 5-10 small apps comfortably
**Current Apps:** 1 (wombatworkouts)
**Available Capacity:** 4-9 more apps
