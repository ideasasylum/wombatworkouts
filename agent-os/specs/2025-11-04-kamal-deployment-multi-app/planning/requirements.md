# Spec Requirements: Kamal 2 Deployment to Hetzner

## Initial Description
Plan deployment of their Wombat Workouts Rails application to a Hetzner server using Kamal 2. They want to be able to host multiple apps on a single server.

## Requirements Discussion

### First Round Questions

**Q1: Reverse Proxy Configuration**
Will you use Traefik (Kamal 2's default) as the reverse proxy, or would you prefer Nginx or Caddy?
**Answer:** Yes, use Traefik (Kamal 2's default)

**Q2: Server Specifications**
What are the specs of your Hetzner server (CPU, RAM, storage)? This will help determine resource allocation strategies for multiple apps.
**Answer:** AX41-NVMe with 6 cores and 64GB RAM (very powerful server!)

**Q3: Domain and DNS Setup**
Do you have a domain registered for the app? Should we include SSL certificate setup via Let's Encrypt in the spec?
**Answer:** Has wombatworkouts.com registered, wants to use that domain

**Q4: SQLite Backup Strategy**
Since the app uses SQLite, do you have a backup solution in place? Should we include Litestream setup for continuous backups to object storage?
**Answer:** Doesn't have a backup solution currently, interested in Litestream setup for continuous backups

**Q5: Multi-App Architecture**
Do you have other apps ready to deploy now, or is this just setting up the infrastructure to support future apps? If you have other apps, what are they?
**Answer:** Will add other hobby Rails apps to the server in the future, but nothing specific planned now. Just wants it ready and setup for multi-apps

**Q6: Container Registry**
Where will Docker images be stored? Options include Docker Hub, GitHub Container Registry (ghcr.io), or setting up a private registry. Do you have a preference?
**Answer:** Use GitHub Container Registry (ghcr.io)

**Q7: Health Checks and Restart Policies**
Should we configure health check endpoints and automatic container restart policies?
**Answer:** Yes to both health checks and automatic container restart policies

**Q8: Monitoring and Logging**
Do you want to include monitoring tools (like AppSignal, Sentry) or just use Kamal's built-in logging?
**Answer:** May add AppSignal in the future, but not part of this spec. Just use Kamal logs for now

**Q9: Background Job Processing**
Does the app currently use Solid Queue for background jobs? Should we deploy it as a separate container or keep jobs in Puma?
**Answer:** Keep jobs in Puma for now - no jobs currently and expects low traffic

**Q10: Scope Boundaries**
Are there any specific features you DON'T want in this deployment? For example: staging environments, CI/CD integration, blue-green deployments, multiple regions, etc.?
**Answer:** All complex deployment features (staging, CI/CD, blue-green deployments, multiple regions, etc.) are out of scope. ONLY requirement is ensuring Rails database migrations run on deployment.

### Existing Code to Reference
No similar existing features identified for reference.

### Follow-up Questions
No follow-up questions needed - all requirements clarified.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
No visual assets provided.

## Requirements Summary

### Functional Requirements
- Deploy Wombat Workouts Rails 8 application to Hetzner AX41-NVMe server (6 cores, 64GB RAM)
- Use Kamal 2 as deployment orchestration tool
- Configure Traefik as reverse proxy for routing traffic
- Set up multi-app capability for hosting multiple Rails apps on single server
- Configure domain wombatworkouts.com with SSL certificates via Let's Encrypt
- Run Rails database migrations automatically on deployment
- Configure health check endpoints for the application
- Set up automatic container restart policies
- Use Kamal's built-in logging (no external monitoring tools)
- Keep background job processing in Puma (no separate Solid Queue container)
- Configure Litestream for continuous SQLite database backups
- Use GitHub Container Registry (ghcr.io) for Docker image storage

### Reusability Opportunities
No existing deployment configurations to reference - this is a greenfield infrastructure setup.

### Scope Boundaries

**In Scope:**
- Kamal 2 configuration for Rails 8 app deployment
- Traefik reverse proxy setup
- Multi-app server architecture
- Domain configuration with SSL certificates (Let's Encrypt)
- Database migration automation
- Health checks and restart policies
- Litestream backup setup for SQLite
- GitHub Container Registry (ghcr.io) configuration

**Out of Scope:**
- Staging environments
- CI/CD integration (GitHub Actions, etc.)
- Blue-green or canary deployments
- Multiple region deployments
- External monitoring tools (AppSignal, Sentry)
- Separate Solid Queue container
- Multiple environment configurations

### Technical Considerations
- Application uses SQLite database (not PostgreSQL)
- Rails 8.1 with Ruby 3.4.7
- Server has significant resources (6 cores, 64GB RAM) allowing multiple apps
- Future apps will be added but not specified yet
- Low traffic expected initially
- Current app has no background job requirements
- WebAuthn authentication requires HTTPS (covered by Let's Encrypt SSL)
- GitHub Container Registry (ghcr.io) chosen for free hosting and integration with existing GitHub repository
- Puma configured with SOLID_QUEUE_IN_PUMA: true environment variable
- Multi-app setup uses Traefik labels for routing different domains/subdomains to different containers
