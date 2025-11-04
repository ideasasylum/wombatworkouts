# Deployment Checklists

## Overview
Use these checklists to ensure consistent, safe deployments of Wombat Workouts to production.

---

## Pre-Deployment Checklist

### Code Readiness

- [ ] All tests passing locally
  ```bash
  bin/rails test
  bin/rails test:system
  ```

- [ ] No uncommitted changes
  ```bash
  git status
  # Should show "working tree clean"
  ```

- [ ] Code reviewed and approved (if using PR workflow)

- [ ] All commits pushed to main branch
  ```bash
  git push origin main
  ```

- [ ] Local branch up to date with remote
  ```bash
  git pull origin main
  ```

### Database Safety

- [ ] Review pending migrations carefully
  ```bash
  bin/rails db:migrate:status
  ```

- [ ] Test migrations run both up and down locally
  ```bash
  bin/rails db:migrate
  bin/rails db:rollback
  bin/rails db:migrate
  ```

- [ ] Migrations are backwards compatible (safe to rollback)

- [ ] No destructive data changes without backup plan

- [ ] Migration rollback strategy documented (if complex)

### Configuration Verification

- [ ] Environment variables set correctly in deploy.yml

- [ ] Secrets file (.kamal/secrets) up to date
  ```bash
  kamal secrets
  # Should output all required variables
  ```

- [ ] RAILS_MASTER_KEY valid and matches config/credentials.yml.enc
  ```bash
  RAILS_MASTER_KEY=$(cat config/master.key) bin/rails credentials:show
  ```

- [ ] No sensitive data in code (credentials, API keys, passwords)

- [ ] No debug code or console.log statements left in

### Build Verification

- [ ] Docker build succeeds locally
  ```bash
  docker build -t wombatworkouts-test .
  ```

- [ ] Ruby version matches Dockerfile and .ruby-version

- [ ] Gemfile.lock committed and up to date

- [ ] Assets precompile without errors (checked in Dockerfile build)

### Infrastructure Readiness

- [ ] Server accessible via SSH
  ```bash
  ssh root@<server-ip> "echo OK"
  ```

- [ ] DNS resolving correctly
  ```bash
  dig wombatworkouts.com
  # Should show correct IP
  ```

- [ ] GitHub Container Registry authentication working
  ```bash
  gh auth status
  # Should show "Logged in to github.com"
  ```

- [ ] Previous deployment healthy
  ```bash
  kamal app details
  curl https://wombatworkouts.com/up
  ```

- [ ] Disk space available on server
  ```bash
  kamal app exec 'df -h'
  # Should have >20% free on all mounts
  ```

### Backup Verification

- [ ] Litestream replication running
  ```bash
  kamal accessory logs litestream --tail 10
  # Should show recent replication messages
  ```

- [ ] Recent backups exist in S3
  ```bash
  ssh root@<server-ip>
  docker exec -it $(docker ps -q -f name=litestream) \
    litestream generations -config /etc/litestream.yml /data/storage/production.sqlite3
  # Should show recent timestamp
  ```

- [ ] Backup lag acceptable (< 5 minutes)

### Communication

- [ ] Team notified of upcoming deployment (if applicable)

- [ ] Maintenance window scheduled (if needed for risky changes)

- [ ] User-facing changes documented for announcement

- [ ] Rollback plan documented and understood

### Timing

- [ ] Deploying during low-traffic period (if possible)

- [ ] Not deploying right before weekend/holiday (unless urgent)

- [ ] Time available to monitor post-deployment (30+ minutes)

- [ ] Team member available for backup (if possible)

---

## During Deployment Checklist

### Initiate Deployment

- [ ] Run deployment command
  ```bash
  kamal deploy
  ```

- [ ] Monitor deployment output for errors

### Watch Build Phase

- [ ] Docker build completes without errors
  - Ruby installation successful
  - Gems install without conflicts
  - Assets precompile successfully
  - Image tagged correctly

- [ ] Image push to ghcr.io succeeds
  - Authentication successful
  - Upload completes fully
  - Image available in registry

### Monitor Deployment Phase

- [ ] Image pulled on server successfully

- [ ] New container starts

- [ ] Database migrations run (if any)
  ```bash
  # Watch logs
  kamal app logs -f
  # Should see "Migrating to..." messages if migrations present
  ```

- [ ] Health checks begin passing
  - First attempt may fail (container starting up)
  - Should see 7 consecutive successes
  - Watch for `/up` endpoint logs

### Traffic Switch

- [ ] Traefik routing updates to new container

- [ ] Old container stops gracefully

- [ ] No 502/503 errors during switch
  ```bash
  # In separate terminal
  while true; do curl -s -o /dev/null -w "%{http_code}\n" https://wombatworkouts.com/up; sleep 1; done
  ```

### Deployment Complete

- [ ] Deployment command completes successfully

- [ ] No error messages in final output

- [ ] New container ID shown as running

---

## Post-Deployment Validation Checklist

### Immediate Checks (Within 5 Minutes)

- [ ] Application accessible
  ```bash
  curl -I https://wombatworkouts.com
  # Should return 200 OK
  ```

- [ ] Health endpoint responding
  ```bash
  curl https://wombatworkouts.com/up
  # Should return 200 OK with HTML
  ```

- [ ] SSL certificate valid
  ```bash
  curl -vI https://wombatworkouts.com 2>&1 | grep "subject:"
  # Should show valid Let's Encrypt cert
  ```

- [ ] No errors in application logs
  ```bash
  kamal app logs --since 5m | grep -i error
  # Should be empty or only expected errors
  ```

- [ ] Correct version deployed
  ```bash
  kamal app details | grep IMAGE
  # Should show latest tag
  ```

### Database Validation (Within 10 Minutes)

- [ ] Migrations completed successfully
  ```bash
  kamal app exec 'bin/rails db:migrate:status'
  # All migrations should be "up"
  ```

- [ ] Database accessible
  ```bash
  kamal console
  # In console:
  User.count
  # Should return number, not error
  ```

- [ ] Database integrity check passes
  ```bash
  kamal app exec 'sqlite3 storage/production.sqlite3 "PRAGMA integrity_check;"'
  # Should return: ok
  ```

- [ ] Database sizes normal
  ```bash
  kamal app exec 'ls -lh storage/'
  # Check sizes haven't unexpectedly changed
  ```

### Application Functionality (Within 15 Minutes)

- [ ] Home page loads correctly
  - Visit https://wombatworkouts.com
  - Check for layout issues
  - Check for JavaScript errors (browser console)

- [ ] User authentication works
  - Log in with test account
  - WebAuthn passkey works
  - Session persists across requests

- [ ] Core features functional
  - View workouts
  - Create new workout
  - Edit existing workout
  - Delete workout
  - Navigate between pages

- [ ] Background jobs processing (if applicable)
  ```bash
  kamal app exec 'bin/rails runner "puts SolidQueue::Job.count"'
  ```

- [ ] Action Cable connections working (if using)
  - WebSocket connections establish
  - Real-time updates function

### System Health (Within 15 Minutes)

- [ ] Container status healthy
  ```bash
  kamal app details
  # Status should be "Up" with recent start time
  ```

- [ ] Memory usage normal
  ```bash
  kamal app exec 'free -h'
  # Used memory should be stable
  ```

- [ ] CPU usage normal
  ```bash
  kamal app exec 'ps aux --sort=-%cpu | head -n 5'
  # No processes using excessive CPU
  ```

- [ ] Disk space unchanged
  ```bash
  kamal app exec 'df -h'
  # No unexpected disk usage spikes
  ```

- [ ] Puma workers running
  ```bash
  kamal app exec 'ps aux | grep puma'
  # Should see master + worker processes
  ```

### Proxy and SSL (Within 15 Minutes)

- [ ] Traefik sees new container
  ```bash
  kamal proxy details
  # Should show wombatworkouts with new container ID
  ```

- [ ] Traefik logs clean
  ```bash
  kamal proxy logs --since 15m | grep -i error
  # Should be empty
  ```

- [ ] SSL certificate valid and not near expiration
  - Visit https://wombatworkouts.com
  - Click padlock → View certificate
  - Expiration should be ~90 days out

- [ ] HTTP redirects to HTTPS
  ```bash
  curl -I http://wombatworkouts.com
  # Should return 301 or 308 redirect to https://
  ```

### Backup Verification (Within 15 Minutes)

- [ ] Litestream still replicating
  ```bash
  kamal accessory logs litestream --since 15m
  # Should see replication messages
  ```

- [ ] All 4 databases backing up
  ```bash
  kamal accessory logs litestream --since 15m | grep -E "(production|cache|queue|cable)"
  # Should see all 4 databases mentioned
  ```

- [ ] Backup lag minimal
  ```bash
  ssh root@<server-ip>
  docker exec -it $(docker ps -q -f name=litestream) \
    litestream generations -config /etc/litestream.yml /data/storage/production.sqlite3
  # Lag should be < 1 minute
  ```

### Extended Monitoring (30 Minutes - 1 Hour)

- [ ] Monitor logs for errors
  ```bash
  kamal app logs -f
  # Watch for unexpected errors
  ```

- [ ] Monitor request patterns
  - Check for 500 errors
  - Check for unusual response times
  - Check for failed requests

- [ ] Monitor memory usage over time
  ```bash
  # Run every 5 minutes
  kamal app exec 'free -h'
  # Memory should be stable
  ```

- [ ] Test user workflows
  - Complete signup flow (if public)
  - Complete key user journeys
  - Test on mobile device
  - Test on different browsers

### Performance Validation (Within 1 Hour)

- [ ] Response times acceptable
  ```bash
  time curl -s https://wombatworkouts.com/up > /dev/null
  # Should be < 500ms
  ```

- [ ] No N+1 queries (check logs for SQL)

- [ ] Asset loading times normal
  - Check browser network tab
  - CSS/JS files loading
  - Images loading

- [ ] Database query performance acceptable
  ```bash
  kamal app logs --since 1h | grep -i "completed.*ms" | tail -n 20
  # Check for slow requests (> 1000ms)
  ```

---

## Rollback Decision Checklist

### When to Consider Rollback

Check if ANY of these are true:

- [ ] Application returning 500 errors consistently

- [ ] Database migration failed or corrupted data

- [ ] Critical feature broken (auth, payments, core workflow)

- [ ] Memory leak causing OOM errors

- [ ] SSL/TLS errors preventing access

- [ ] Data loss or corruption detected

- [ ] Security vulnerability introduced

- [ ] Performance degradation > 50% (response times doubled)

### Rollback Execution

If rollback needed:

1. [ ] Announce rollback to team

2. [ ] Execute rollback
   ```bash
   kamal rollback
   ```

3. [ ] Monitor rollback process

4. [ ] Verify application functional after rollback

5. [ ] Document reason for rollback

6. [ ] Create hotfix plan

7. [ ] Test fix locally before redeploying

---

## Post-Deployment Communication Checklist

### Success Communication

- [ ] Notify team deployment succeeded

- [ ] Document what was deployed
  - Version/commit deployed
  - New features added
  - Bug fixes included
  - Database changes made

- [ ] Update changelog or release notes

- [ ] Announce user-facing changes (if any)

- [ ] Update documentation (if needed)

### Failure Communication

- [ ] Notify team of rollback

- [ ] Document failure cause

- [ ] Create incident report (if major)

- [ ] Schedule post-mortem (if needed)

- [ ] Create action items to prevent recurrence

---

## Weekly Deployment Review Checklist

### Review Deployment History

- [ ] Check deployment frequency

- [ ] Review successful deployments

- [ ] Review failed deployments

- [ ] Identify patterns in failures

### Infrastructure Health

- [ ] Review disk usage trends
  ```bash
  kamal app exec 'df -h'
  ```

- [ ] Review memory usage trends
  ```bash
  kamal app exec 'free -h'
  ```

- [ ] Review database growth
  ```bash
  kamal app exec 'ls -lh storage/'
  ```

- [ ] Review backup logs
  ```bash
  kamal accessory logs litestream --since 7d | grep -i error
  ```

### Process Improvements

- [ ] Update checklists based on learnings

- [ ] Document new issues encountered

- [ ] Update runbooks with new procedures

- [ ] Share deployment tips with team

---

## Monthly Deployment Audit Checklist

### Deployment Metrics

- [ ] Total deployments this month

- [ ] Successful deployment rate

- [ ] Average deployment time

- [ ] Rollback frequency

### System Health Trends

- [ ] Server resource utilization trends

- [ ] Database growth rate

- [ ] Backup size trends

- [ ] SSL certificate expiration dates

### Infrastructure Review

- [ ] Review and update Kamal configuration

- [ ] Review and update secrets

- [ ] Review and update Litestream configuration

- [ ] Test complete disaster recovery

### Documentation Review

- [ ] Update deployment runbook

- [ ] Update troubleshooting guides

- [ ] Update monitoring documentation

- [ ] Update team onboarding docs

---

## Emergency Deployment Checklist

### When Deploying Critical Fix

Abbreviated checklist for urgent deployments:

- [ ] Verify fix locally
  ```bash
  bin/rails test
  ```

- [ ] Create hotfix branch (if using git-flow)

- [ ] Push to GitHub
  ```bash
  git push origin main
  ```

- [ ] Verify secrets and configuration
  ```bash
  kamal secrets
  ```

- [ ] Announce deployment to team

- [ ] Deploy
  ```bash
  kamal deploy
  ```

- [ ] Monitor deployment closely

- [ ] Test critical functionality immediately

- [ ] Verify fix resolves issue

- [ ] Monitor for 30 minutes minimum

- [ ] Document incident and fix

---

## Checklist Maintenance

### Review These Checklists

- [ ] **Monthly:** Review and update based on learnings

- [ ] **After incidents:** Add new checks to prevent recurrence

- [ ] **After major changes:** Update for new infrastructure

- [ ] **Team feedback:** Incorporate suggestions from team

### Keep Checklists Current

- [ ] Remove obsolete checks

- [ ] Add new validation steps

- [ ] Update commands for new Kamal versions

- [ ] Update URLs and endpoints

- [ ] Update team contacts and escalation procedures

---

## Quick Reference - Minimal Deployment

For experienced deployers, the absolute minimum checks:

### Before
```bash
git status  # Clean
bin/rails test  # Passing
kamal secrets  # Valid
```

### Deploy
```bash
kamal deploy  # Monitor output
```

### After
```bash
curl https://wombatworkouts.com/up  # 200 OK
kamal app logs --since 5m  # No errors
# Test in browser
```

### Monitor
```bash
kamal app logs -f  # Watch for 15 minutes
```

---

**Last Updated:** 2025-11-04
**Review Schedule:** Monthly
**Next Review:** 2025-12-04
