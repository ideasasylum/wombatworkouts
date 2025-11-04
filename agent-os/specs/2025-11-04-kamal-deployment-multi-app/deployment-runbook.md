# Deployment Runbook - Wombat Workouts

## Overview
This runbook provides step-by-step instructions for deploying and managing the Wombat Workouts Rails application on Hetzner using Kamal 2.

**Service:** wombatworkouts
**Domain:** wombatworkouts.com
**Server:** Hetzner AX41-NVMe (6 cores, 64GB RAM)
**Registry:** ghcr.io/ideasasylum/wombatworkouts

---

## Regular Deployment

### Deploy New Version

Deploy the latest code changes to production:

```bash
kamal deploy
```

**What this does:**
1. Builds Docker image locally with latest code
2. Pushes image to GitHub Container Registry (ghcr.io)
3. Pulls new image on Hetzner server
4. Runs database migrations via docker-entrypoint (db:prepare)
5. Starts new container on different port
6. Waits for health checks to pass (7 consecutive checks at /up endpoint)
7. Updates Traefik routing to point to new container
8. Stops and removes old container
9. Zero-downtime deployment via asset bridging

**Expected Duration:** 5-10 minutes

**What to Monitor:**
- Docker build completes without errors
- Image push to ghcr.io succeeds
- Health checks pass (watch for 7/7 successes)
- SSL certificate remains valid
- No errors in application logs

---

## Rollback

### Roll Back to Previous Version

If a deployment causes issues, quickly roll back to the previous version:

```bash
kamal rollback
```

**What this does:**
1. Finds the previous Docker image tag
2. Pulls previous image from registry
3. Starts container with previous version
4. Waits for health checks to pass
5. Updates Traefik routing back to previous container
6. Removes current (problematic) container

**Expected Duration:** Under 2 minutes

**When to Use:**
- New deployment causes application errors
- Performance degradation after deployment
- Database migration issues that can't be fixed forward
- Critical bugs discovered in production

**Important Notes:**
- Rollback does NOT undo database migrations
- If migration is incompatible, you may need to restore from backup
- Always verify application functionality after rollback
- Consider hotfix deployment instead of staying on old version

---

## Log Viewing

### View Application Logs (Real-Time)

Stream live application logs from the production container:

```bash
kamal app logs -f
```

**Alias:** `kamal logs` (configured in deploy.yml)

**What you'll see:**
- Rails application logs
- Puma web server output
- Solid Queue job processing (if jobs are running)
- Request/response logs
- Error traces and stack traces

**Usage Tips:**
- Press Ctrl+C to stop streaming
- Logs persist for the lifetime of the container
- Use `kamal app logs --since 1h` to see last hour only
- Use `kamal app logs --tail 100` to see last 100 lines

### View Litestream Backup Logs

Monitor database backup activity:

```bash
kamal accessory logs litestream -f
```

**What you'll see:**
- Replication status for all 4 databases
- Backup completion messages
- Upload confirmations to S3
- Any backup errors or warnings

---

## Rails Console Access

### Open Interactive Rails Console

Access Rails console for production debugging and data inspection:

```bash
kamal console
```

**Alias for:** `kamal app exec --interactive --reuse "bin/rails console"`

**What this gives you:**
- Full Rails console access in production environment
- Direct access to ActiveRecord models
- Ability to query and inspect data
- Run Rails commands interactively

**Safety Warnings:**
- You are in PRODUCTION - changes are permanent
- Be extremely careful with data modifications
- Avoid running destructive commands
- Consider using read-only queries when possible

**Example Usage:**
```ruby
# Check user count
User.count

# Find specific record
workout = Workout.find(123)

# Inspect configuration
Rails.application.credentials.config
```

---

## Database Console Access

### Open Interactive Database Console

Access SQLite database console directly:

```bash
kamal dbc
```

**Alias for:** `kamal app exec --interactive --reuse "bin/rails dbconsole --include-password"`

**What this gives you:**
- Direct SQLite3 shell access
- Run SQL queries directly
- Inspect schema and tables
- Database administration

**Safety Warnings:**
- Direct SQL bypasses Rails validations
- No automatic backup before changes
- Easy to corrupt data if not careful
- Use Rails console for data operations when possible

**Example Usage:**
```sql
-- List all tables
.tables

-- Show schema for users table
.schema users

-- Count workouts
SELECT COUNT(*) FROM workouts;

-- Exit
.quit
```

---

## Shell Access

### Open Interactive Bash Shell

Access container shell for advanced debugging:

```bash
kamal shell
```

**Alias for:** `kamal app exec --interactive --reuse "bash"`

**What this gives you:**
- Full bash shell inside running container
- Access to file system
- Ability to run system commands
- Inspect environment variables

**Common Use Cases:**
- Check disk space: `df -h`
- List database files: `ls -lh storage/`
- View environment: `env | grep RAILS`
- Check Ruby version: `ruby -v`
- Inspect Gemfile.lock: `cat Gemfile.lock`

---

## Container Management

### View Container Details

Get detailed information about running application containers:

```bash
kamal app details
```

**What this shows:**
- Container ID and status
- Docker image tag currently running
- Port mappings
- Volume mounts
- Environment variables
- Health check status
- Restart policy

**Example Output:**
```
App Host: 123.456.789.012
CONTAINER ID   IMAGE                                      STATUS    PORTS
abc123def456   ghcr.io/ideasasylum/wombatworkouts:v123   Up 2hrs   80/tcp
```

### Restart Application Container

Restart the application without redeploying:

```bash
kamal app restart
```

**When to Use:**
- Configuration changes that need reload
- Clear stuck processes
- Apply environment variable changes
- Troubleshoot performance issues

**Note:** This does NOT redeploy - it just restarts existing container

---

## Advanced Operations

### Execute Custom Commands

Run any command inside the production container:

```bash
kamal app exec '<command>'
```

**Examples:**

Check running processes:
```bash
kamal app exec 'ps aux'
```

Check disk usage:
```bash
kamal app exec 'df -h'
```

Check database file sizes:
```bash
kamal app exec 'ls -lh storage/'
```

Run rake task:
```bash
kamal app exec 'bin/rails db:migrate:status'
```

Check memory usage:
```bash
kamal app exec 'free -h'
```

### View Container Configuration

See full Kamal configuration:

```bash
kamal config
```

**What this shows:**
- Parsed deploy.yml configuration
- Resolved environment variables
- Server targets
- Proxy settings
- Volume mounts
- All Kamal settings

---

## Traefik Proxy Management

### View Proxy Status

Check Traefik reverse proxy details:

```bash
kamal proxy details
```

**What this shows:**
- Traefik container status
- Configured routes and hostnames
- SSL certificate status
- Let's Encrypt configuration
- Registered backend services

### View Proxy Logs

Monitor Traefik proxy logs:

```bash
kamal proxy logs -f
```

**What you'll see:**
- HTTP requests being proxied
- SSL/TLS handshakes
- Certificate renewals
- Routing decisions
- Backend health checks

### Restart Proxy

Restart Traefik proxy (rarely needed):

```bash
kamal proxy restart
```

**When to Use:**
- Certificate renewal issues
- Routing configuration not updating
- Proxy container stuck or unresponsive

---

## Litestream Backup Management

### View Backup Status

Check Litestream accessory status:

```bash
kamal accessory details litestream
```

**What this shows:**
- Litestream container status
- Volume mounts
- Environment variables configured
- Container health

### Restart Litestream

Restart backup service:

```bash
kamal accessory restart litestream
```

**When to Use:**
- Backup replication stopped
- Configuration changes to litestream.yml
- Troubleshooting backup issues

### Stop/Start Litestream

Stop backup service:
```bash
kamal accessory stop litestream
```

Start backup service:
```bash
kamal accessory start litestream
```

---

## Monitoring Commands

### Container Health

Check if container is running and healthy:

```bash
kamal app details
```

Look for "Up" status and healthy state.

### Process Monitoring

View running processes inside container:

```bash
kamal app exec 'ps aux'
```

**What to look for:**
- Puma master process running
- Puma worker processes (based on WEB_CONCURRENCY)
- Solid Queue supervisor (if enabled)
- Rails processes

### Disk Usage

Check disk space on server and in container:

```bash
kamal app exec 'df -h'
```

**Monitor:**
- /rails/storage volume (SQLite databases)
- Root filesystem (Docker images)
- Look for >80% usage as warning sign

### Database Size

Check SQLite database file sizes:

```bash
kamal app exec 'ls -lh storage/'
```

**Files to monitor:**
- production.sqlite3 (main database)
- production_cache.sqlite3 (cache)
- production_queue.sqlite3 (jobs)
- production_cable.sqlite3 (websockets)

### Memory Usage

View container memory consumption:

```bash
kamal app exec 'free -h'
```

---

## Troubleshooting

### Deployment Failures

If `kamal deploy` fails:

1. Check build errors:
   ```bash
   docker build -t test .
   ```

2. Verify GitHub authentication:
   ```bash
   gh auth status
   ```

3. Check server connectivity:
   ```bash
   ssh root@<server-ip>
   ```

4. View deployment logs:
   ```bash
   kamal app logs --tail 100
   ```

### Health Check Failures

If health checks don't pass:

1. Check /up endpoint manually:
   ```bash
   curl https://wombatworkouts.com/up
   ```

2. View application logs:
   ```bash
   kamal app logs -f
   ```

3. Check database connectivity:
   ```bash
   kamal app exec 'bin/rails db:migrate:status'
   ```

### SSL Certificate Issues

If HTTPS not working:

1. Check DNS resolution:
   ```bash
   dig wombatworkouts.com
   ```

2. View Traefik logs:
   ```bash
   kamal proxy logs --tail 100
   ```

3. Check proxy configuration:
   ```bash
   kamal proxy details
   ```

4. Verify Let's Encrypt rate limits (50 certs/week per domain)

### Backup Not Running

If Litestream not backing up:

1. Check Litestream logs:
   ```bash
   kamal accessory logs litestream --tail 100
   ```

2. Verify S3 credentials:
   ```bash
   kamal accessory details litestream
   ```

3. Restart Litestream:
   ```bash
   kamal accessory restart litestream
   ```

4. Check cloud storage bucket exists and is accessible

---

## Quick Reference

### Most Common Commands

| Command | Purpose |
|---------|---------|
| `kamal deploy` | Deploy new version |
| `kamal rollback` | Roll back to previous version |
| `kamal logs` | View application logs |
| `kamal console` | Open Rails console |
| `kamal dbc` | Open database console |
| `kamal app details` | Check container status |
| `kamal proxy details` | Check Traefik status |
| `kamal accessory logs litestream` | Check backup logs |

### Emergency Contacts

- **Kamal Documentation:** https://kamal-deploy.org/
- **Traefik Documentation:** https://doc.traefik.io/traefik/
- **Litestream Documentation:** https://litestream.io/
- **Server Provider:** Hetzner (https://www.hetzner.com/)

---

## Deployment Schedule

### Recommended Practices

- **Deploy during low-traffic hours:** Early morning or late evening
- **Monitor for 15-30 minutes post-deployment:** Watch logs and error rates
- **Have rollback plan ready:** Know how to quickly roll back if issues arise
- **Test locally first:** Always test changes in development before deploying
- **One change at a time:** Easier to identify what caused issues
- **Database migrations:** Review migrations carefully before deploying

### Deployment Checklist

See `deployment-checklist.md` for comprehensive pre/post deployment checklists.

---

## Security Notes

### Secrets Management

- Never commit `.kamal/secrets` to git
- Never commit `config/master.key` to git
- Rotate GitHub token periodically
- Keep cloud storage credentials secure
- Use environment variables for sensitive data

### Access Control

- Limit who has SSH access to production server
- Limit who can run Kamal deployment commands
- Monitor GitHub Container Registry access
- Review Hetzner server access logs periodically

### SSL/TLS

- Let's Encrypt automatically renews certificates
- Certificates valid for 90 days, renew every 60 days
- Monitor certificate expiration via Traefik logs
- Ensure wombatworkouts.com always redirects HTTP to HTTPS

---

**Last Updated:** 2025-11-04
**Kamal Version:** 2.x
**Rails Version:** 8.1
**Ruby Version:** 3.4.7
