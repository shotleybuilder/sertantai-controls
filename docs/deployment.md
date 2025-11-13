# Deployment Guide

## Overview

This application deploys to the **~/Desktop/infrastructure** production environment:

1. **Backend Services** - Added to infrastructure's docker-compose.yml
2. **Frontend** - Static assets on CDN (Cloudflare Pages/Netlify)

## Infrastructure Project

Production deployment uses the shared infrastructure at `~/Desktop/infrastructure` which provides:

- **Shared PostgreSQL 16**: Multiple databases on single instance
- **Shared Redis 7**: Caching and sessions
- **Nginx Reverse Proxy**: Subdomain routing with SSL
- **Centralized Management**: Single `docker-compose.yml`, unified backups

## Prerequisites

- Access to `~/Desktop/infrastructure` repository
- Domain configured with DNS pointing to droplet
- Frontend CDN account (Cloudflare/Netlify)
- Secrets management

## Backend Deployment (to Infrastructure)

### Step 1: Add Database to PostgreSQL Init Script

Edit `~/Desktop/infrastructure/data/postgres-init/01-create-databases.sql`:

```sql
-- Add sertantai_controls database
CREATE DATABASE sertantai_controls_prod;
GRANT ALL PRIVILEGES ON DATABASE sertantai_controls_prod TO postgres;
```

### Step 2: Add Services to docker-compose.yml

Edit `~/Desktop/infrastructure/docker/docker-compose.yml`:

```yaml
services:
  # ... existing services (postgres, redis, nginx, etc.)

  # Sertantai Controls Backend
  sertantai-controls:
    build: /path/to/sertantai-controls/backend
    image: sertantai-controls:${SERTANTAI_VERSION:-latest}
    container_name: sertantai-controls
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/sertantai_controls_prod
      REDIS_URL: redis://redis:6379/2
      SECRET_KEY_BASE: ${SERTANTAI_SECRET_KEY_BASE}
      GUARDIAN_SECRET_KEY: ${SERTANTAI_GUARDIAN_SECRET}
      GUARDIAN_ISSUER: sertantai_controls
      PHX_HOST: ${SERTANTAI_HOST}
      FRONTEND_URL: ${SERTANTAI_FRONTEND_URL}
      ELECTRIC_URL: http://sertantai-controls-electric:5133
      PORT: 4000
      MIX_ENV: prod
    networks:
      - infra_network
    depends_on:
      - postgres
      - redis
      - sertantai-controls-electric
    restart: unless-stopped
    mem_limit: 1g
    mem_reservation: 512m
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ElectricSQL for Sertantai Controls
  sertantai-controls-electric:
    image: electricsql/electric:latest
    container_name: sertantai-controls-electric
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/sertantai_controls_prod
      LOGICAL_PUBLISHER_HOST: postgres
      LOGICAL_PUBLISHER_PORT: 5432
    networks:
      - infra_network
    depends_on:
      - postgres
    restart: unless-stopped

  # Auth Proxy for Electric
  sertantai-controls-proxy:
    build: /path/to/sertantai-controls/proxy
    container_name: sertantai-controls-proxy
    environment:
      ELECTRIC_URL: http://sertantai-controls-electric:5133
      JWT_SECRET: ${SERTANTAI_GUARDIAN_SECRET}
      JWT_ISSUER: sertantai_controls
    networks:
      - infra_network
    depends_on:
      - sertantai-controls-electric
    restart: unless-stopped
```

### Step 3: Add Environment Variables

Edit `~/Desktop/infrastructure/docker/.env`:

```bash
# Sertantai Controls Configuration
SERTANTAI_VERSION=latest
SERTANTAI_HOST=app.yourdomain.com
SERTANTAI_FRONTEND_URL=https://app.yourdomain.com
SERTANTAI_SECRET_KEY_BASE=<generate-with-mix-phx.gen.secret>
SERTANTAI_GUARDIAN_SECRET=<generate-with-mix-guardian.gen.secret>
```

### Step 4: Add Nginx Configuration

Create `~/Desktop/infrastructure/nginx/conf.d/sertantai-controls.conf`:

```nginx
# Sertantai Controls - app.yourdomain.com
upstream sertantai_controls_backend {
    server sertantai-controls:4000;
}

upstream sertantai_controls_proxy {
    server sertantai-controls-proxy:3000;
}

server {
    listen 80;
    listen [::]:80;
    server_name app.yourdomain.com;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name app.yourdomain.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/app.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.yourdomain.com/privkey.pem;

    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Proxy to backend API
    location /api/ {
        proxy_pass http://sertantai_controls_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Proxy to Electric auth proxy
    location /v1/shape {
        proxy_pass http://sertantai_controls_proxy;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Frontend served by CDN, so just health check here
    location /health {
        proxy_pass http://sertantai_controls_backend;
    }
}
```

### Step 5: Deploy Services

```bash
cd ~/Desktop/infrastructure/docker

# Pull latest images and rebuild
docker-compose build sertantai-controls sertantai-controls-proxy

# Start services
docker-compose up -d sertantai-controls sertantai-controls-electric sertantai-controls-proxy

# Check status
docker-compose ps

# View logs
docker-compose logs -f sertantai-controls
```

### Step 6: Run Migrations

```bash
# Execute migrations in container
docker-compose exec sertantai-controls /app/bin/sertantai_controls eval "SertantaiControls.Release.migrate()"
```

### Step 7: Setup SSL

```bash
cd ~/Desktop/infrastructure

# Add domain to certbot
./migration-scripts/03-setup-ssl.sh app.yourdomain.com
```

## Frontend Deployment (Cloudflare Pages)

### Step 1: Install Wrangler

```bash
npm install -g wrangler
```

### Step 2: Login

```bash
wrangler login
```

### Step 3: Build and Deploy

```bash
cd ~/Desktop/sertantai-controls/frontend

# Build for production
npm run build

# Deploy to Cloudflare Pages
wrangler pages deploy build --project-name=sertantai-controls
```

### Step 4: Configure Environment Variables

In Cloudflare Pages dashboard, set:

```
PUBLIC_API_URL=https://app.yourdomain.com/api
PUBLIC_ELECTRIC_PROXY_URL=https://app.yourdomain.com/v1/shape
PUBLIC_ENV=production
```

## Database Management

### Backups

Infrastructure project handles automated backups:

```bash
cd ~/Desktop/infrastructure

# Create backup (includes all databases)
./scripts/backup.sh

# Backups stored in backups/ directory
# Auto-cleanup after 7 days
```

### Restore from Backup

```bash
cd ~/Desktop/infrastructure
./scripts/restore.sh backups/baserow_backup_YYYYMMDD_HHMMSS.tar.gz
```

## Monitoring

### Application Monitoring

Configure AppSignal or New Relic:

```elixir
# config/prod.exs
config :appsignal, :config,
  active: true,
  name: "Sertantai Controls",
  push_api_key: System.get_env("APPSIGNAL_PUSH_API_KEY")
```

### Error Tracking

Configure Sentry:

```elixir
# config/prod.exs
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: :prod
```

### Health Checks

- Backend: `https://api.example.com/health`
- Frontend: `https://app.example.com/` (should load)

## Rollback Procedures

### Backend Rollback

```bash
cd ~/Desktop/infrastructure/docker

# Revert to previous image version
docker-compose pull sertantai-controls:previous-version
docker-compose up -d sertantai-controls

# Or restore from backup
../scripts/restore.sh backups/baserow_backup_YYYYMMDD_HHMMSS.tar.gz
```

### Frontend Rollback

```bash
# Cloudflare Pages
wrangler pages deployment list --project-name=sertantai-controls
wrangler pages deployment rollback <deployment-id>
```

### Database Rollback

```bash
# Execute rollback in container
cd ~/Desktop/infrastructure/docker
docker-compose exec sertantai-controls /app/bin/sertantai_controls eval "SertantaiControls.Repo.rollback(SertantaiControls.Repo, 1)"
```

## SSL/TLS

SSL is managed by the infrastructure project using Let's Encrypt:

```bash
cd ~/Desktop/infrastructure

# Setup SSL for new subdomain
./migration-scripts/03-setup-ssl.sh app.yourdomain.com

# Renew certificates (automatic via cron, but manual if needed)
sudo certbot renew
docker-compose exec nginx nginx -s reload
```

## Performance Optimization

### Backend

- Enable connection pooling
- Configure proper VM memory
- Use CDN for static assets
- Enable response compression

### Frontend

- Enable CDN caching
- Optimize images
- Code splitting
- Tree shaking

## Security Checklist

- [ ] All secrets in environment variables (not code)
- [ ] CORS configured for production domain only
- [ ] Rate limiting enabled
- [ ] Database connection uses SSL
- [ ] No debug endpoints in production
- [ ] Dependency security scan passing
- [ ] JWT secrets are strong and unique

## Troubleshooting

### Service Won't Start

Check logs:
```bash
cd ~/Desktop/infrastructure/docker
docker-compose logs sertantai-controls
docker-compose logs sertantai-controls-electric
docker-compose logs sertantai-controls-proxy
```

Check service status:
```bash
docker-compose ps
```

### Database Connection Issues

Verify database exists:
```bash
docker-compose exec postgres psql -U postgres -l | grep sertantai_controls
```

Test connection:
```bash
docker-compose exec sertantai-controls /app/bin/sertantai_controls remote
```

### CORS Errors

1. Verify `FRONTEND_URL` in infrastructure `.env`
2. Check frontend is using correct API URL
3. Check Nginx proxy headers are set correctly

### Electric Sync Issues

Check Electric is running:
```bash
docker-compose logs sertantai-controls-electric
```

Verify logical replication is enabled:
```bash
docker-compose exec postgres psql -U postgres -c "SHOW wal_level;"
# Should show 'logical'
```

### SSL Certificate Issues

```bash
cd ~/Desktop/infrastructure

# Check certificate status
sudo certbot certificates

# Manual renewal if needed
sudo certbot renew
docker-compose exec nginx nginx -s reload
```

## Additional Resources

- [Infrastructure Project](~/Desktop/infrastructure/README.md)
- [Cloudflare Pages Docs](https://developers.cloudflare.com/pages/)
- [Phoenix Deployment](https://hexdocs.pm/phoenix/deployment.html)
- [ElectricSQL Docs](https://electric-sql.com/docs)
