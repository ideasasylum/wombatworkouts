# Specification: Kamal 2 Deployment to Hetzner with Multi-App Support

## Goal
Deploy Wombat Workouts Rails 8 application to Hetzner server using Kamal 2, with infrastructure configured to support multiple Rails applications on a single server in the future.

## User Stories
- As a developer, I want to deploy my Rails app to production using Kamal 2 so that I can host it on my Hetzner server
- As a developer, I want automatic SSL certificates via Let's Encrypt so that WebAuthn authentication works securely over HTTPS
- As a developer, I want database migrations to run automatically on each deployment so that the schema stays in sync
- As a developer, I want continuous SQLite backups via Litestream so that I don't lose data
- As a developer, I want the infrastructure ready for multiple apps so that I can host future Rails hobby projects on the same server
- As a developer, I want health checks and automatic restarts so that the application stays available

## Core Requirements
- Deploy Rails 8.1 (Ruby 3.4.6) application to Hetzner AX41-NVMe server
- Configure Traefik reverse proxy for routing with SSL termination
- Enable automatic SSL certificates via Let's Encrypt for wombatworkouts.com
- Run Rails database migrations automatically on each deployment
- Configure health checks using Rails built-in /up endpoint
- Set up automatic container restart policies
- Configure Litestream for continuous SQLite backup to cloud storage
- Use GitHub Container Registry (ghcr.io) for Docker images
- Support multi-app architecture for future Rails applications

## Existing Configuration
### Already Configured
The application has existing Kamal configuration that needs to be updated:

- **Dockerfile**: Production-ready with Ruby 3.4.6, uses Thruster web server on port 80
- **Docker entrypoint**: Already runs `bin/rails db:prepare` for migrations
- **Health check endpoint**: `/up` route exists (rails/health#show)
- **Database**: SQLite with 4 separate databases (primary, cache, queue, cable) in storage/ directory
- **Volume mount**: wombatworkouts_storage volume already configured
- **Asset bridging**: Already configured for zero-downtime deployments
- **Solid Queue**: SOLID_QUEUE_IN_PUMA: true already set

### Needs Configuration
- Server IP address (currently placeholder: 192.168.0.1)
- Container registry (currently localhost:5555, needs ghcr.io)
- Proxy/SSL settings (currently commented out)
- Traefik labels for multi-app support
- Litestream accessory for backups
- GitHub Container Registry authentication
- Production domain configuration

## Technical Approach

### 1. Update Kamal Configuration (config/deploy.yml)

**Update registry to use GitHub Container Registry:**
```yaml
registry:
  server: ghcr.io
  username: <github-username>
  password:
    - KAMAL_REGISTRY_PASSWORD
```

**Update server configuration:**
```yaml
servers:
  web:
    - <hetzner-server-ip>
```

**Enable Traefik proxy with SSL:**
```yaml
proxy:
  ssl: true
  host: wombatworkouts.com
  app_port: 80
```

**Configure Traefik labels for multi-app routing:**
```yaml
labels:
  traefik.http.routers.wombatworkouts.rule: Host(`wombatworkouts.com`)
  traefik.http.routers.wombatworkouts.entrypoints: websecure
  traefik.http.routers.wombatworkouts.tls.certresolver: letsencrypt
```

**Add Litestream accessory for SQLite backups:**
```yaml
accessories:
  litestream:
    image: litestream/litestream:latest
    host: <hetzner-server-ip>
    volumes:
      - "wombatworkouts_storage:/data"
      - "/etc/litestream.yml:/etc/litestream.yml"
    cmd: replicate
    env:
      secret:
        - LITESTREAM_ACCESS_KEY_ID
        - LITESTREAM_SECRET_ACCESS_KEY
```

**Configure health checks:**
```yaml
healthcheck:
  path: /up
  port: 80
  max_attempts: 7
  interval: 10s
```

**Update image name for ghcr.io:**
```yaml
image: <github-username>/wombatworkouts
```

### 2. Update Kamal Secrets (.kamal/secrets)

Add GitHub Container Registry authentication:
```bash
KAMAL_REGISTRY_PASSWORD=$(gh auth token)
```

Add Litestream credentials for cloud storage:
```bash
LITESTREAM_ACCESS_KEY_ID=<your-access-key>
LITESTREAM_SECRET_ACCESS_KEY=<your-secret-key>
```

### 3. Create Litestream Configuration

Create `/etc/litestream.yml` on server for SQLite replication:
```yaml
dbs:
  - path: /data/storage/production.sqlite3
    replicas:
      - url: s3://<bucket-name>/production.sqlite3
  - path: /data/storage/production_cache.sqlite3
    replicas:
      - url: s3://<bucket-name>/production_cache.sqlite3
  - path: /data/storage/production_queue.sqlite3
    replicas:
      - url: s3://<bucket-name>/production_queue.sqlite3
  - path: /data/storage/production_cable.sqlite3
    replicas:
      - url: s3://<bucket-name>/production_cable.sqlite3
```

### 4. Update Docker Build Configuration

Verify Ruby version in Dockerfile matches .ruby-version:
- Current Dockerfile uses 3.4.6
- .ruby-version file shows 3.4.6
- Requirements specify 3.4.7 - needs update to .ruby-version and Dockerfile ARG

### 5. DNS Configuration

Configure DNS records for wombatworkouts.com:
- A record pointing to Hetzner server IP
- Wait for DNS propagation before running kamal setup

### 6. Multi-App Architecture Setup

For future applications, the Traefik configuration will support:
- Host-based routing (different domains)
- Path-based routing (different paths on same domain)
- Multiple Let's Encrypt certificates

Each new app will need:
- Separate Kamal service name
- Unique Traefik labels with different host rules
- Own Docker volumes for isolation
- Same Traefik proxy instance (shared)

## Deployment Workflow

### Initial Setup (One-Time)
1. Configure DNS: Point wombatworkouts.com to Hetzner server IP
2. Update Ruby version: Change .ruby-version and Dockerfile to 3.4.7
3. Update config/deploy.yml with production values
4. Update .kamal/secrets with GitHub token and Litestream credentials
5. Push Litestream config to server: `scp litestream.yml root@<server>:/etc/litestream.yml`
6. Run initial setup: `kamal setup`

### Regular Deployment
1. Make code changes
2. Commit to git
3. Run: `kamal deploy`

Kamal will automatically:
- Build Docker image locally
- Push to GitHub Container Registry
- Pull image on server
- Run database migrations (via docker-entrypoint)
- Start new container
- Wait for health check to pass
- Switch Traefik routing to new container
- Remove old container

### Rollback
If deployment fails:
```bash
kamal rollback
```

### Monitoring
- View logs: `kamal app logs -f`
- Check app status: `kamal app details`
- Access console: `kamal console`
- Access database: `kamal dbc`

## Testing and Validation

### Pre-Deployment Checks
1. Verify DNS resolution: `dig wombatworkouts.com`
2. Verify server connectivity: `ssh root@<server-ip>`
3. Verify GitHub token: `gh auth status`
4. Verify secrets file is not in git: `git status .kamal/secrets`
5. Test Docker build locally: `docker build -t test .`

### Post-Deployment Validation
1. HTTP redirect: Visit http://wombatworkouts.com (should redirect to HTTPS)
2. SSL certificate: Verify Let's Encrypt cert at https://wombatworkouts.com
3. Health check: `curl https://wombatworkouts.com/up` (should return 200)
4. WebAuthn: Test passkey authentication works over HTTPS
5. Database: Verify migrations ran: `kamal app exec 'bin/rails db:migrate:status'`
6. Litestream: Check backup status: `kamal accessory logs litestream`
7. Traefik: Verify routing: `kamal proxy details`
8. Container restart: Kill container and verify auto-restart

### Load Testing
Given low expected traffic, formal load testing is not required. Monitor resource usage after deployment:
```bash
kamal app exec 'ps aux'
kamal app exec 'df -h'
```

## Reusable Components

### Existing Code to Leverage
- **Dockerfile**: Production-ready, no changes needed (except Ruby version bump)
- **docker-entrypoint**: Already handles migrations via `db:prepare`
- **deploy.yml**: Good foundation, needs production values
- **Volume configuration**: Already correct for SQLite
- **Asset bridging**: Already configured for zero-downtime deploys
- **Health endpoint**: Already implemented at /up

### New Components Required
- **Litestream configuration**: No existing backup solution
- **GitHub Container Registry setup**: Currently uses local registry
- **Traefik proxy configuration**: Currently commented out
- **Production secrets**: Need GitHub token and cloud storage credentials
- **DNS configuration**: Need to configure domain
- **Multi-app labels**: Need Traefik labels for future apps

## Out of Scope
- Staging environment configuration
- CI/CD pipeline setup (GitHub Actions)
- Blue-green deployment strategy
- Canary deployments
- Multi-region deployment
- External monitoring tools (AppSignal, Sentry)
- Separate Solid Queue container
- Multiple environment configurations (development, staging)
- Database restore procedures (Litestream restore is documented separately)
- Custom Traefik middleware (rate limiting, auth)
- Server provisioning/hardening (assumes clean Hetzner server)
- Backup retention policies (use Litestream defaults)

## Success Criteria
- Application accessible at https://wombatworkouts.com with valid SSL certificate
- WebAuthn authentication works over HTTPS
- Deployment completes in under 10 minutes
- Database migrations run automatically on each deploy
- Health checks pass consistently (7 consecutive successes)
- Container auto-restarts on failure
- Litestream continuously backs up all 4 SQLite databases
- Zero-downtime deployments (asset bridging works)
- Infrastructure supports adding new Rails apps with different domains
- Rollback completes in under 2 minutes

## Future Considerations

### Adding Additional Rails Applications
When deploying future apps to the same server:

1. Create new Rails app with own config/deploy.yml
2. Use unique service name: `service: myapp`
3. Configure separate domain/subdomain
4. Use same Traefik proxy (it's shared across apps)
5. Add Traefik labels with new host rule:
   ```yaml
   labels:
     traefik.http.routers.myapp.rule: Host(`myapp.com`)
   ```
6. Use separate Docker volumes for isolation
7. Deploy: `kamal setup` from new app directory

### Resource Monitoring
With 6 cores and 64GB RAM, the server can handle many small Rails apps. Monitor:
- Memory usage per container
- CPU usage during deployments
- Disk I/O for SQLite databases
- Network bandwidth

Consider adding AppSignal or similar monitoring when running multiple production apps.

### Backup Strategy
Litestream provides continuous replication, but consider:
- Testing restore procedure before production use
- Retention policy for old backups
- Disaster recovery plan
- Database snapshot before major migrations

### Performance Optimization
As traffic grows, consider:
- Increasing WEB_CONCURRENCY for more Puma workers
- Splitting Solid Queue to dedicated container
- Adding Redis for action cable/cache (currently using SQLite)
- CDN for static assets
- Database query optimization
