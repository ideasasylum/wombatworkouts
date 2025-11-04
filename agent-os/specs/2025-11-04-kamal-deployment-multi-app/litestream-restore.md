# Litestream Database Restore Guide

## Overview
This guide explains how to restore SQLite databases from Litestream backups in case of data loss, corruption, or disaster recovery scenarios.

**Important:** Litestream provides continuous replication to S3-compatible storage. Backups are incremental and near-real-time, typically within seconds of database changes.

---

## Understanding Litestream Backups

### What Gets Backed Up

Wombat Workouts backs up 4 SQLite databases:
1. **production.sqlite3** - Main application database (users, workouts, etc.)
2. **production_cache.sqlite3** - Rails cache
3. **production_queue.sqlite3** - Solid Queue jobs
4. **production_cable.sqlite3** - Action Cable connections

### Backup Location

Backups are stored in your S3-compatible bucket (configured in litestream.yml):
```
s3://YOUR_BUCKET_NAME/production.sqlite3/
s3://YOUR_BUCKET_NAME/production_cache.sqlite3/
s3://YOUR_BUCKET_NAME/production_queue.sqlite3/
s3://YOUR_BUCKET_NAME/production_cable.sqlite3/
```

### Backup Format

Litestream stores:
- **Full snapshots** - Complete database copy taken periodically
- **WAL segments** - Write-Ahead Log segments for incremental changes
- **Generations** - Multiple backup versions over time

---

## Listing Available Backups

### View Generations for a Database

Connect to the server and run Litestream commands through the accessory container:

```bash
# SSH to server
ssh root@<server-ip>

# List generations for primary database
docker exec -it $(docker ps -q -f name=litestream) \
  litestream generations -config /etc/litestream.yml /data/storage/production.sqlite3
```

**Example output:**
```
name                                 generation  lag    start                     end
s3://bucket/production.sqlite3       abc123...   5s     2024-11-04T10:00:00Z     2024-11-04T12:30:45Z
s3://bucket/production.sqlite3       def456...   -      2024-11-03T08:00:00Z     2024-11-03T23:59:59Z
```

**What this shows:**
- **name:** Backup replica URL
- **generation:** Unique identifier for backup version
- **lag:** How far behind real-time (smaller = more recent)
- **start:** When this generation began
- **end:** When this generation ended (or is current)

### List All Database Generations

Check all 4 databases:

```bash
# Primary database
docker exec -it $(docker ps -q -f name=litestream) \
  litestream generations -config /etc/litestream.yml /data/storage/production.sqlite3

# Cache database
docker exec -it $(docker ps -q -f name=litestream) \
  litestream generations -config /etc/litestream.yml /data/storage/production_cache.sqlite3

# Queue database
docker exec -it $(docker ps -q -f name=litestream) \
  litestream generations -config /etc/litestream.yml /data/storage/production_queue.sqlite3

# Cable database
docker exec -it $(docker ps -q -f name=litestream) \
  litestream generations -config /etc/litestream.yml /data/storage/production_cable.sqlite3
```

---

## Restore Procedures

### Important Pre-Restore Steps

Before restoring any database:

1. **Stop the application** to prevent data corruption:
   ```bash
   # From local machine with Kamal
   kamal app stop
   ```

2. **Backup current database** (if recoverable):
   ```bash
   # SSH to server
   ssh root@<server-ip>

   # Copy current databases to backup location
   docker run --rm -v wombatworkouts_storage:/data -v $(pwd):/backup \
     alpine sh -c "cd /data/storage && tar czf /backup/pre-restore-$(date +%Y%m%d-%H%M%S).tar.gz production*.sqlite3*"
   ```

3. **Verify backup exists** in S3 (use listings above)

### Restore Primary Database (Full Procedure)

**Scenario:** Restore production.sqlite3 to latest backup

```bash
# SSH to server
ssh root@<server-ip>

# Stop Wombat Workouts application
docker stop $(docker ps -q -f name=wombatworkouts-web)

# Stop Litestream (important to avoid conflicts)
docker stop $(docker ps -q -f name=litestream)

# Remove corrupted database file
docker run --rm -v wombatworkouts_storage:/data alpine \
  rm /data/storage/production.sqlite3

# Restore from Litestream backup
docker run --rm \
  -v wombatworkouts_storage:/data \
  -v /etc/litestream.yml:/etc/litestream.yml \
  -e LITESTREAM_ACCESS_KEY_ID="$LITESTREAM_ACCESS_KEY_ID" \
  -e LITESTREAM_SECRET_ACCESS_KEY="$LITESTREAM_SECRET_ACCESS_KEY" \
  litestream/litestream:latest \
  restore -config /etc/litestream.yml /data/storage/production.sqlite3

# Restart Litestream
docker start $(docker ps -aq -f name=litestream)

# Restart Wombat Workouts
docker start $(docker ps -aq -f name=wombatworkouts-web)
```

**Or use Kamal from local machine:**

```bash
# Stop app
kamal app stop

# SSH to server and restore
ssh root@<server-ip> << 'EOF'
  # Stop Litestream
  docker stop $(docker ps -q -f name=litestream)

  # Remove old database
  docker run --rm -v wombatworkouts_storage:/data alpine \
    rm /data/storage/production.sqlite3

  # Restore from backup
  docker run --rm \
    -v wombatworkouts_storage:/data \
    -v /etc/litestream.yml:/etc/litestream.yml \
    -e LITESTREAM_ACCESS_KEY_ID="$LITESTREAM_ACCESS_KEY_ID" \
    -e LITESTREAM_SECRET_ACCESS_KEY="$LITESTREAM_SECRET_ACCESS_KEY" \
    litestream/litestream:latest \
    restore -config /etc/litestream.yml /data/storage/production.sqlite3

  # Restart Litestream
  docker start $(docker ps -aq -f name=litestream)
EOF

# Restart app
kamal app start
```

### Restore to Specific Point in Time

**Scenario:** Restore database to state before a bad migration or data corruption

```bash
# List available generations and their timestamps
docker exec -it $(docker ps -q -f name=litestream) \
  litestream generations -config /etc/litestream.yml /data/storage/production.sqlite3

# Note the timestamp you want to restore to
# Example: 2024-11-04T10:30:00Z

# Stop services
docker stop $(docker ps -q -f name=wombatworkouts-web)
docker stop $(docker ps -q -f name=litestream)

# Remove current database
docker run --rm -v wombatworkouts_storage:/data alpine \
  rm /data/storage/production.sqlite3

# Restore to specific timestamp
docker run --rm \
  -v wombatworkouts_storage:/data \
  -v /etc/litestream.yml:/etc/litestream.yml \
  -e LITESTREAM_ACCESS_KEY_ID="$LITESTREAM_ACCESS_KEY_ID" \
  -e LITESTREAM_SECRET_ACCESS_KEY="$LITESTREAM_SECRET_ACCESS_KEY" \
  litestream/litestream:latest \
  restore -config /etc/litestream.yml \
  -timestamp 2024-11-04T10:30:00Z \
  /data/storage/production.sqlite3

# Restart services
docker start $(docker ps -aq -f name=litestream)
docker start $(docker ps -aq -f name=wombatworkouts-web)
```

### Restore to Specific Generation

**Scenario:** Restore from an older backup generation

```bash
# List generations and note the generation ID
docker exec -it $(docker ps -q -f name=litestream) \
  litestream generations -config /etc/litestream.yml /data/storage/production.sqlite3

# Example generation: abc123def456...

# Stop services
docker stop $(docker ps -q -f name=wombatworkouts-web)
docker stop $(docker ps -q -f name=litestream)

# Restore specific generation
docker run --rm \
  -v wombatworkouts_storage:/data \
  -v /etc/litestream.yml:/etc/litestream.yml \
  -e LITESTREAM_ACCESS_KEY_ID="$LITESTREAM_ACCESS_KEY_ID" \
  -e LITESTREAM_SECRET_ACCESS_KEY="$LITESTREAM_SECRET_ACCESS_KEY" \
  litestream/litestream:latest \
  restore -config /etc/litestream.yml \
  -generation abc123def456 \
  /data/storage/production.sqlite3

# Restart services
docker start $(docker ps -aq -f name=litestream)
docker start $(docker ps -aq -f name=wombatworkouts-web)
```

### Restore All Databases

**Scenario:** Complete disaster recovery - restore all 4 databases

```bash
# Stop services
kamal app stop

# SSH to server
ssh root@<server-ip>

# Stop Litestream
docker stop $(docker ps -q -f name=litestream)

# Restore primary database
docker run --rm \
  -v wombatworkouts_storage:/data \
  -v /etc/litestream.yml:/etc/litestream.yml \
  -e LITESTREAM_ACCESS_KEY_ID="$LITESTREAM_ACCESS_KEY_ID" \
  -e LITESTREAM_SECRET_ACCESS_KEY="$LITESTREAM_SECRET_ACCESS_KEY" \
  litestream/litestream:latest \
  restore -config /etc/litestream.yml /data/storage/production.sqlite3

# Restore cache database
docker run --rm \
  -v wombatworkouts_storage:/data \
  -v /etc/litestream.yml:/etc/litestream.yml \
  -e LITESTREAM_ACCESS_KEY_ID="$LITESTREAM_ACCESS_KEY_ID" \
  -e LITESTREAM_SECRET_ACCESS_KEY="$LITESTREAM_SECRET_ACCESS_KEY" \
  litestream/litestream:latest \
  restore -config /etc/litestream.yml /data/storage/production_cache.sqlite3

# Restore queue database
docker run --rm \
  -v wombatworkouts_storage:/data \
  -v /etc/litestream.yml:/etc/litestream.yml \
  -e LITESTREAM_ACCESS_KEY_ID="$LITESTREAM_ACCESS_KEY_ID" \
  -e LITESTREAM_SECRET_ACCESS_KEY="$LITESTREAM_SECRET_ACCESS_KEY" \
  litestream/litestream:latest \
  restore -config /etc/litestream.yml /data/storage/production_queue.sqlite3

# Restore cable database
docker run --rm \
  -v wombatworkouts_storage:/data \
  -v /etc/litestream.yml:/etc/litestream.yml \
  -e LITESTREAM_ACCESS_KEY_ID="$LITESTREAM_ACCESS_KEY_ID" \
  -e LITESTREAM_SECRET_ACCESS_KEY="$LITESTREAM_SECRET_ACCESS_KEY" \
  litestream/litestream:latest \
  restore -config /etc/litestream.yml /data/storage/production_cable.sqlite3

# Restart services
docker start $(docker ps -aq -f name=litestream)
docker start $(docker ps -aq -f name=wombatworkouts-web)

# Or from local machine
kamal app start
```

### Restore to Local Machine for Testing

**Scenario:** Test restore without affecting production

```bash
# Create local directory for restored databases
mkdir -p ~/restore-test

# Set credentials
export LITESTREAM_ACCESS_KEY_ID="your-key-id"
export LITESTREAM_SECRET_ACCESS_KEY="your-secret-key"

# Copy litestream.yml from project
cp litestream.yml ~/restore-test/

# Restore to local directory
docker run --rm \
  -v ~/restore-test:/data \
  -v ~/restore-test/litestream.yml:/etc/litestream.yml \
  -e LITESTREAM_ACCESS_KEY_ID \
  -e LITESTREAM_SECRET_ACCESS_KEY \
  litestream/litestream:latest \
  restore -config /etc/litestream.yml /data/production.sqlite3

# Check restored database
sqlite3 ~/restore-test/production.sqlite3 "SELECT COUNT(*) FROM users;"
```

---

## Disaster Recovery Scenarios

### Scenario 1: Accidental Data Deletion

**Problem:** User accidentally deleted important records

**Solution:**
1. Identify when data was deleted (check application logs)
2. Find timestamp just before deletion
3. Restore database to that timestamp
4. Export deleted records
5. Restore current database
6. Import deleted records

**Commands:**
```bash
# Restore to before deletion
docker run --rm -v wombatworkouts_storage:/data ... \
  restore -timestamp 2024-11-04T10:00:00Z /data/storage/production.sqlite3

# Export needed data
kamal app exec 'bin/rails runner "User.where(...).to_csv"' > recovered_data.csv

# Restore to latest
docker run --rm -v wombatworkouts_storage:/data ... \
  restore /data/storage/production.sqlite3

# Import recovered data through Rails console
kamal console
```

### Scenario 2: Failed Database Migration

**Problem:** Migration corrupted database schema

**Solution:**
1. Stop application
2. Restore database to before migration
3. Fix migration code
4. Redeploy with corrected migration

**Commands:**
```bash
# Stop app
kamal app stop

# Find timestamp before migration (check deployment logs)
# Restore to that point
docker run --rm -v wombatworkouts_storage:/data ... \
  restore -timestamp 2024-11-04T09:55:00Z /data/storage/production.sqlite3

# Fix migration in code
# Redeploy
kamal deploy
```

### Scenario 3: Complete Server Failure

**Problem:** Hetzner server died completely, need to restore on new server

**Solution:**
1. Provision new Hetzner server
2. Update DNS to point to new server IP
3. Update deploy.yml with new server IP
4. Run kamal setup (creates volumes and containers)
5. Stop application and Litestream
6. Restore all databases from S3
7. Start services
8. Verify functionality

**Commands:**
```bash
# Update deploy.yml with new server IP
# Run setup
kamal setup

# SSH to new server
ssh root@<new-server-ip>

# Stop services
docker stop $(docker ps -q -f name=wombatworkouts-web)
docker stop $(docker ps -q -f name=litestream)

# Restore all 4 databases (see "Restore All Databases" above)

# Start services
docker start $(docker ps -aq -f name=litestream)
docker start $(docker ps -aq -f name=wombatworkouts-web)

# Verify
curl https://wombatworkouts.com/up
```

### Scenario 4: Database Corruption

**Problem:** SQLite database corrupted, can't open

**Solution:**
1. Check Litestream replication status
2. Stop services
3. Remove corrupted database
4. Restore from latest backup
5. Verify database integrity
6. Restart services

**Commands:**
```bash
# Check corruption
kamal app exec 'sqlite3 storage/production.sqlite3 "PRAGMA integrity_check;"'

# If corrupted, restore
kamal app stop
ssh root@<server-ip>
docker stop $(docker ps -q -f name=litestream)

# Remove corrupted file
docker run --rm -v wombatworkouts_storage:/data alpine \
  rm /data/storage/production.sqlite3

# Restore
docker run --rm -v wombatworkouts_storage:/data ... \
  restore /data/storage/production.sqlite3

# Verify integrity
docker run --rm -v wombatworkouts_storage:/data alpine \
  sqlite3 /data/storage/production.sqlite3 "PRAGMA integrity_check;"

# Start services
docker start $(docker ps -aq -f name=litestream)
kamal app start
```

---

## Verification After Restore

### Check Database Integrity

```bash
# SSH to server
ssh root@<server-ip>

# Check primary database integrity
docker run --rm -v wombatworkouts_storage:/data alpine \
  sqlite3 /data/storage/production.sqlite3 "PRAGMA integrity_check;"

# Should return: ok
```

### Check Database Contents

```bash
# From local machine
kamal console

# In Rails console
User.count
Workout.count
# etc.

# Check latest records to verify recency
User.last
Workout.last
```

### Check Application Functionality

```bash
# Test health endpoint
curl https://wombatworkouts.com/up

# Test login
# Navigate to https://wombatworkouts.com and log in

# Test key features
# Create workout, edit program, etc.
```

### Check Litestream Replication Resumed

```bash
# View Litestream logs
kamal accessory logs litestream -f

# Should see replication messages:
# "replicating to..."
# "snapshot written..."
```

---

## Backup Testing Schedule

### Regular Testing (Monthly)

Test restore procedure monthly to ensure backups are working:

```bash
# 1. List generations (should see recent backups)
ssh root@<server-ip>
docker exec -it $(docker ps -q -f name=litestream) \
  litestream generations -config /etc/litestream.yml /data/storage/production.sqlite3

# 2. Restore to local machine for testing
mkdir -p ~/backup-test-$(date +%Y%m%d)
docker run --rm \
  -v ~/backup-test-$(date +%Y%m%d):/data \
  -v /etc/litestream.yml:/etc/litestream.yml \
  -e LITESTREAM_ACCESS_KEY_ID \
  -e LITESTREAM_SECRET_ACCESS_KEY \
  litestream/litestream:latest \
  restore -config /etc/litestream.yml /data/production.sqlite3

# 3. Verify restored database
sqlite3 ~/backup-test-$(date +%Y%m%d)/production.sqlite3 \
  "SELECT COUNT(*) FROM users; SELECT COUNT(*) FROM workouts;"

# 4. Document results
echo "Backup test $(date): SUCCESS" >> backup-test-log.txt
```

### Before Major Changes

Test restore before:
- Major Rails upgrades
- Large database migrations
- Server migrations
- Application rewrites

---

## Troubleshooting Restore Issues

### "No snapshots found" Error

**Problem:** Litestream can't find backup in S3

**Solutions:**
1. Check S3 credentials are correct
2. Verify bucket name in litestream.yml
3. Check bucket permissions
4. List bucket contents to verify files exist

```bash
# Using AWS CLI (if available)
aws s3 ls s3://YOUR_BUCKET_NAME/production.sqlite3/

# Check Litestream can access S3
docker run --rm \
  -e LITESTREAM_ACCESS_KEY_ID \
  -e LITESTREAM_SECRET_ACCESS_KEY \
  litestream/litestream:latest \
  replicate -config /etc/litestream.yml
```

### Restore Taking Too Long

**Problem:** Restore seems stuck

**Solutions:**
1. Check network connectivity to S3
2. Large databases take time (be patient)
3. Check Litestream container logs for errors
4. Verify enough disk space on server

```bash
# Check disk space
df -h

# Monitor restore progress (in separate terminal)
watch docker stats
```

### Restored Database is Empty

**Problem:** Database restored but has no data

**Solutions:**
1. Verify you restored correct database path
2. Check if restore actually completed
3. Try restoring specific generation instead of latest
4. Check if backup was actually running

```bash
# Verify backup was running
kamal accessory logs litestream --since 24h | grep production.sqlite3

# Should see replication messages
```

### Permissions Errors

**Problem:** Can't read/write restored database

**Solutions:**
1. Check volume mount permissions
2. Restore using same user as application
3. Fix ownership after restore

```bash
# Fix ownership
docker run --rm -v wombatworkouts_storage:/data alpine \
  chown -R 1000:1000 /data/storage/
```

---

## Environment Variables for Restore

When running restore commands, you need these environment variables:

```bash
# Set before running restore
export LITESTREAM_ACCESS_KEY_ID="your-access-key-id"
export LITESTREAM_SECRET_ACCESS_KEY="your-secret-access-key"

# Or source from .kamal/secrets (on local machine)
source .kamal/secrets
```

For non-AWS S3 providers (Backblaze B2, DigitalOcean Spaces):

```bash
# Add endpoint configuration to litestream.yml
replicas:
  - url: s3://bucket/path
    endpoint: https://s3.region.backblazeb2.com  # For B2
    # or
    endpoint: https://region.digitaloceanspaces.com  # For Spaces
```

---

## Backup Retention

Litestream default retention policy:
- **Snapshots:** Every 24 hours, kept for 7 days
- **WAL segments:** Continuously, kept for 24 hours after snapshot
- **Generations:** Old generations deleted after retention period

**To customize retention**, edit litestream.yml:

```yaml
dbs:
  - path: /data/storage/production.sqlite3
    replicas:
      - url: s3://bucket/production.sqlite3
        retention: 168h  # 7 days (default)
        snapshot-interval: 24h  # Daily snapshots (default)
```

---

## Emergency Contact Information

**Litestream Documentation:**
- Restore guide: https://litestream.io/guides/restore/
- Command reference: https://litestream.io/reference/restore/

**Support Resources:**
- Litestream GitHub: https://github.com/benbjohnson/litestream
- Litestream Discord: https://discord.gg/litestream

---

## Quick Reference

### Most Common Restore Commands

```bash
# List available backups
docker exec -it $(docker ps -q -f name=litestream) \
  litestream generations -config /etc/litestream.yml /data/storage/production.sqlite3

# Restore latest backup
docker run --rm -v wombatworkouts_storage:/data ... \
  restore -config /etc/litestream.yml /data/storage/production.sqlite3

# Restore to specific time
docker run --rm -v wombatworkouts_storage:/data ... \
  restore -timestamp 2024-11-04T10:30:00Z /data/storage/production.sqlite3

# Restore specific generation
docker run --rm -v wombatworkouts_storage:/data ... \
  restore -generation abc123 /data/storage/production.sqlite3
```

---

**Last Updated:** 2025-11-04
**Litestream Version:** latest
**S3 Provider:** [Configured in litestream.yml]
