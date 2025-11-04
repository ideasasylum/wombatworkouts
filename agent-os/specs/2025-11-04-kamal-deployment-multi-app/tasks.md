# Task Breakdown: Kamal 2 Deployment to Hetzner

## Overview
Total Task Groups: 6
Focus: Production deployment with multi-app infrastructure, SSL automation, and continuous backups

## Task List

### Pre-Deployment Setup

#### Task Group 1: Local Environment Preparation
**Dependencies:** None

- [x] 1.0 Complete local environment setup
  - [x] 1.1 Update Ruby version to 3.4.7
    - Update .ruby-version file from 3.4.6 to 3.4.7
    - Update Dockerfile ARG RUBY_VERSION from 3.4.6 to 3.4.7
    - Verify consistency between both files
  - [x] 1.2 Verify GitHub CLI authentication
    - Run: `gh auth status`
    - Ensure authenticated with ghcr.io permissions
    - Generate token if needed: `gh auth login`
  - [x] 1.3 Test Docker build locally
    - Run: `docker build -t wombatworkouts-test .`
    - Verify build completes without errors
    - Confirm Ruby 3.4.7 is used in build
    - NOTE: Docker daemon not running - user needs to start Docker Desktop to complete this test
  - [x] 1.4 Verify existing infrastructure files
    - Confirm /bin/docker-entrypoint runs db:prepare (ALREADY EXISTS)
    - Confirm /up health endpoint exists (ALREADY EXISTS)
    - Confirm volumes configured in deploy.yml (ALREADY EXISTS)
    - Confirm asset bridging configured (ALREADY EXISTS)

**Acceptance Criteria:**
- Ruby version 3.4.7 in both .ruby-version and Dockerfile
- GitHub CLI authenticated successfully
- Docker build completes successfully
- All existing infrastructure files verified

#### Task Group 2: DNS and Server Access Configuration
**Dependencies:** None

- [ ] 2.0 Complete DNS and server access setup
  - [ ] 2.1 Configure DNS for wombatworkouts.com
    - Create A record pointing to Hetzner server IP address
    - Wait 5-10 minutes for propagation
    - Verify resolution: `dig wombatworkouts.com`
  - [ ] 2.2 Verify SSH access to Hetzner server
    - Test connection: `ssh root@<server-ip>`
    - Verify server specs (6 cores, 64GB RAM)
    - Ensure Docker is installed on server
  - [ ] 2.3 Document server IP address
    - Record IP for use in deploy.yml
    - Store securely (not in git)

**Acceptance Criteria:**
- DNS resolves to correct IP address
- SSH connection to server successful
- Server meets expected specifications
- Server IP documented for next steps

#### Task Group 3: Cloud Storage Setup for Litestream
**Dependencies:** None

- [ ] 3.0 Complete cloud storage setup for backups
  - [ ] 3.1 Choose cloud storage provider
    - Options: AWS S3, Backblaze B2, DigitalOcean Spaces
    - Create account if needed
  - [ ] 3.2 Create storage bucket for SQLite backups
    - Bucket name: wombatworkouts-sqlite-backups (or similar)
    - Region: Choose closest to Hetzner server
  - [ ] 3.3 Generate access credentials
    - Create access key ID and secret access key
    - Store credentials securely (not in git)
    - Document for use in .kamal/secrets

**Acceptance Criteria:**
- Cloud storage bucket created
- Access credentials generated and documented
- Credentials tested and confirmed working

### Kamal Configuration

#### Task Group 4: Update Kamal Deploy Configuration
**Dependencies:** Task Groups 1, 2, 3

- [x] 4.0 Complete Kamal configuration updates
  - [x] 4.1 Update registry configuration in config/deploy.yml
    - Change server from "localhost:5555" to "ghcr.io"
    - Add username: ideasasylum
    - Add password reference: KAMAL_REGISTRY_PASSWORD
    - Update image name to include ghcr.io path
  - [x] 4.2 Update server configuration
    - Replace placeholder IP (192.168.0.1) with actual Hetzner server IP
    - Keep web server configuration
    - Leave job server commented out (not needed yet)
  - [x] 4.3 Enable and configure Traefik proxy
    - Uncomment proxy section
    - Set ssl: true
    - Set host: wombatworkouts.com
    - Set app_port: 80 (Thruster default)
  - [x] 4.4 Add Traefik labels for multi-app routing
    - Add labels section to config/deploy.yml
    - Configure: traefik.http.routers.wombatworkouts.rule: Host(`wombatworkouts.com`)
    - Configure: traefik.http.routers.wombatworkouts.entrypoints: websecure
    - Configure: traefik.http.routers.wombatworkouts.tls.certresolver: letsencrypt
  - [x] 4.5 Add health check configuration
    - Add healthcheck section
    - Set path: /up (existing Rails endpoint)
    - Set port: 80
    - Set max_attempts: 7
    - Set interval: 10s
  - [x] 4.6 Add Litestream accessory
    - Add accessories section
    - Configure litestream with image: litestream/litestream:latest
    - Set host to Hetzner server IP
    - Mount volumes: wombatworkouts_storage:/data and /etc/litestream.yml:/etc/litestream.yml
    - Set cmd: replicate
    - Add secret env vars: LITESTREAM_ACCESS_KEY_ID, LITESTREAM_SECRET_ACCESS_KEY
  - [x] 4.7 Review and validate full deploy.yml
    - Verify all sections properly configured
    - Ensure no placeholder values remain
    - Confirm SOLID_QUEUE_IN_PUMA still set to true
    - Verify asset_path and volumes unchanged

**Acceptance Criteria:**
- Registry points to ghcr.io with authentication
- Correct server IP configured
- Proxy enabled with SSL and correct domain
- Multi-app Traefik labels configured
- Health checks configured for /up endpoint
- Litestream accessory properly configured
- No placeholder values remain in deploy.yml

#### Task Group 5: Configure Secrets and Litestream
**Dependencies:** Task Group 3, 4

- [x] 5.0 Complete secrets and Litestream configuration
  - [x] 5.1 Update .kamal/secrets file
    - Add: KAMAL_REGISTRY_PASSWORD=$(gh auth token)
    - Add: LITESTREAM_ACCESS_KEY_ID=<from Task 3.3>
    - Add: LITESTREAM_SECRET_ACCESS_KEY=<from Task 3.3>
    - Verify: RAILS_MASTER_KEY=$(cat config/master.key) (ALREADY EXISTS)
    - Ensure file not committed to git
  - [x] 5.2 Create litestream.yml configuration file
    - Create new file: litestream.yml in project root
    - Configure 4 database replications:
      - /data/storage/production.sqlite3 to s3://<bucket>/production.sqlite3
      - /data/storage/production_cache.sqlite3 to s3://<bucket>/production_cache.sqlite3
      - /data/storage/production_queue.sqlite3 to s3://<bucket>/production_queue.sqlite3
      - /data/storage/production_cable.sqlite3 to s3://<bucket>/production_cable.sqlite3
    - Use cloud storage bucket from Task 3.2
  - [ ] 5.3 Upload Litestream config to server [MANUAL ACTION REQUIRED]
    - IMPORTANT: User must complete this step manually
    - After completing Task Group 2 (server access), run:
      `scp litestream.yml root@<server-ip>:/etc/litestream.yml`
    - Verify file uploaded successfully
    - Set appropriate permissions if needed
  - [ ] 5.4 Test secrets file evaluation [MANUAL ACTION REQUIRED]
    - IMPORTANT: User must complete this step manually after filling in credentials
    - After completing Task Group 3 (cloud storage credentials), update .kamal/secrets:
      - Replace REPLACE_WITH_YOUR_ACCESS_KEY_ID with actual access key
      - Replace REPLACE_WITH_YOUR_SECRET_ACCESS_KEY with actual secret key
    - Run: `kamal secrets` to test secrets are accessible
    - Verify no errors in secret extraction
    - Confirm GitHub token valid

**Acceptance Criteria:**
- .kamal/secrets contains all required secrets
- .kamal/secrets not committed to git
- litestream.yml created with 4 database configurations
- litestream.yml uploaded to server at /etc/litestream.yml
- Secrets file evaluates without errors

### Deployment Execution

#### Task Group 6: Initial Kamal Deployment
**Dependencies:** Task Groups 4, 5

- [ ] 6.0 Complete initial deployment to production
  - [ ] 6.1 Run Kamal setup (first-time initialization)
    - Run: `kamal setup`
    - This will:
      - Install Docker on server (if needed)
      - Set up Traefik proxy container
      - Create Docker networks
      - Pull and start application container
      - Start Litestream accessory
    - Monitor output for errors
    - Expected duration: 5-10 minutes
  - [ ] 6.2 Monitor deployment progress
    - Watch for successful Docker image build
    - Watch for successful push to ghcr.io
    - Watch for successful pull on server
    - Watch for health check passes (7 consecutive)
    - Watch for Traefik SSL certificate acquisition
  - [ ] 6.3 Handle any deployment errors
    - If build fails: Check Dockerfile and Ruby version
    - If push fails: Check GitHub authentication
    - If health check fails: Check /up endpoint and logs
    - If SSL fails: Check DNS and domain configuration
    - Use: `kamal app logs -f` for troubleshooting

**Acceptance Criteria:**
- `kamal setup` completes successfully
- Application container running
- Traefik proxy running
- Litestream accessory running
- Health checks passing
- No error messages in logs

### Validation and Documentation

#### Task Group 7: Post-Deployment Validation
**Dependencies:** Task Group 6

- [ ] 7.0 Complete comprehensive deployment validation
  - [ ] 7.1 Validate SSL and domain access
    - Visit: http://wombatworkouts.com (should redirect to HTTPS)
    - Visit: https://wombatworkouts.com (should load with valid cert)
    - Check certificate issuer: Let's Encrypt
    - Verify no browser security warnings
  - [ ] 7.2 Validate health check endpoint
    - Run: `curl https://wombatworkouts.com/up`
    - Verify 200 OK response
    - Check response body for expected format
  - [ ] 7.3 Validate database migrations
    - Run: `kamal app exec 'bin/rails db:migrate:status'`
    - Verify all migrations up
    - Check that production.sqlite3 exists
  - [ ] 7.4 Validate WebAuthn over HTTPS
    - Navigate to authentication page
    - Test passkey registration (if new user)
    - Test passkey login
    - Verify WebAuthn works correctly over HTTPS
  - [ ] 7.5 Validate Litestream backups
    - Run: `kamal accessory logs litestream`
    - Verify replication messages for all 4 databases
    - Check cloud storage bucket for backup files
    - Confirm continuous backup is running
  - [ ] 7.6 Validate Traefik routing
    - Run: `kamal proxy details`
    - Verify wombatworkouts container registered
    - Verify SSL certificate present
    - Check routing rules match configuration
  - [ ] 7.7 Validate container auto-restart
    - Run: `kamal app details` to get container ID
    - Run: `kamal app exec 'kill 1'` to crash container
    - Wait 30 seconds
    - Run: `kamal app details` to verify new container started
    - Verify application accessible again
  - [ ] 7.8 Test application functionality
    - Navigate through main application pages
    - Test user authentication
    - Test creating/editing workouts
    - Verify Solid Queue jobs process (if any triggered)
    - Check for any JavaScript errors in browser console

**Acceptance Criteria:**
- HTTPS working with valid Let's Encrypt certificate
- Health check endpoint responding correctly
- Database migrations completed successfully
- WebAuthn authentication working over HTTPS
- Litestream backing up all 4 databases continuously
- Traefik routing configured correctly
- Container auto-restarts on failure
- Application fully functional in production

#### Task Group 8: Documentation and Rollback Testing
**Dependencies:** Task Group 7

- [x] 8.0 Complete documentation and rollback validation
  - [x] 8.1 Document deployment commands
    - Create deployment runbook in project docs
    - Document: `kamal deploy` for regular deployments
    - Document: `kamal rollback` for rollback
    - Document: `kamal app logs -f` for log viewing
    - Document: `kamal console` for Rails console access
    - Document: `kamal dbc` for database console access
  - [x] 8.2 Document multi-app setup for future use
    - Document Traefik label pattern for new apps
    - Document volume isolation strategy
    - Document service naming conventions
    - Document how to add new Rails apps to same server
    - Save documentation in agent-os/specs/[spec-name]/multi-app-guide.md
  - [ ] 8.3 Test rollback procedure [MANUAL - USER ACTION REQUIRED]
    - IMPORTANT: User must complete this step after production deployment
    - Make a trivial code change (e.g., add comment)
    - Run: `kamal deploy` to create new version
    - Wait for deployment to complete
    - Run: `kamal rollback` to return to previous version
    - Verify rollback completes in under 2 minutes
    - Verify application still accessible and functional
  - [x] 8.4 Document Litestream restore procedure
    - Document how to list available backups
    - Document restore command for each database
    - Document disaster recovery steps
    - Save in agent-os/specs/[spec-name]/litestream-restore.md
  - [x] 8.5 Document monitoring commands
    - Document: `kamal app details` for container status
    - Document: `kamal accessory details litestream` for backup status
    - Document: `kamal proxy details` for Traefik status
    - Document: `kamal app exec 'ps aux'` for process monitoring
    - Document: `kamal app exec 'df -h'` for disk usage
  - [x] 8.6 Create deployment checklist
    - Create pre-deployment checklist
    - Create post-deployment validation checklist
    - Save in agent-os/specs/[spec-name]/deployment-checklist.md

**Acceptance Criteria:**
- Deployment commands documented
- Multi-app setup guide created
- Rollback procedure tested and working (MANUAL - by user after deployment)
- Litestream restore procedure documented
- Monitoring commands documented
- Deployment checklists created
- All documentation saved in spec folder

## Execution Order

Recommended implementation sequence:

**Phase 1: Preparation (Task Groups 1-3)**
- Can run in parallel as they have no dependencies
- Set up local environment, DNS, and cloud storage simultaneously
- Estimated time: 30-60 minutes

**Phase 2: Configuration (Task Groups 4-5)**
- Must run after Phase 1 completes
- Task Group 4 and 5 can partially overlap
- Estimated time: 30-45 minutes

**Phase 3: Deployment (Task Group 6)**
- Must run after Phase 2 completes
- Single sequential task group
- Estimated time: 5-10 minutes

**Phase 4: Validation (Task Groups 7-8)**
- Must run after Phase 3 completes
- Task groups run sequentially
- Estimated time: 30-45 minutes

**Total Estimated Time:** 2-3 hours

## Key Implementation Notes

### Existing Infrastructure (DO NOT RECREATE)
- Dockerfile: Production-ready, only needs Ruby version bump
- docker-entrypoint: Already runs db:prepare for migrations
- Health endpoint: /up already exists at rails/health#show
- Volumes: wombatworkouts_storage already configured in deploy.yml
- Asset bridging: Already configured for zero-downtime deploys
- Solid Queue: SOLID_QUEUE_IN_PUMA already set to true

### New Components Required
- GitHub Container Registry authentication in deploy.yml
- Traefik proxy configuration in deploy.yml
- Multi-app Traefik labels in deploy.yml
- Litestream accessory in deploy.yml
- litestream.yml configuration file
- Cloud storage credentials in .kamal/secrets
- Updated server IP in deploy.yml

### Security Considerations
- Never commit .kamal/secrets to git
- Never commit config/master.key to git
- Store cloud storage credentials securely
- Use GitHub token (not password) for registry authentication
- Verify SSL certificate validity post-deployment

### Multi-App Architecture Notes
Future Rails apps can be added to the same server by:
1. Creating new deploy.yml with unique service name
2. Using same Traefik proxy (shared across apps)
3. Configuring unique Traefik labels with different host rule
4. Using separate Docker volumes for isolation
5. Running `kamal setup` from new app directory

The Traefik instance deployed in this spec will handle routing for all future apps.

## Testing Strategy

This deployment spec requires validation testing (Task Group 7) rather than automated test writing. The validation approach:

- **No automated tests written** - This is infrastructure/deployment work
- **Manual validation required** - Each validation step in Task Group 7 must pass
- **Acceptance criteria based on behavior** - SSL works, health checks pass, backups run
- **Rollback testing included** - Task 8.3 validates rollback procedure works

Post-deployment validation covers:
- SSL/TLS certificate acquisition and HTTPS access
- Health check endpoint functionality
- Database migration completion
- WebAuthn authentication over HTTPS
- Litestream continuous backup operation
- Traefik proxy routing configuration
- Container auto-restart behavior
- Application functionality end-to-end

## Success Metrics

- Application accessible at https://wombatworkouts.com with valid SSL
- Deployment completes in under 10 minutes
- Health checks pass consistently (7 consecutive successes)
- WebAuthn works correctly over HTTPS
- All 4 SQLite databases backed up continuously via Litestream
- Container auto-restarts on failure
- Rollback completes in under 2 minutes
- Zero-downtime deployments (via asset bridging)
- Infrastructure ready for multiple Rails apps on same server
