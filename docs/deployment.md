# Deployment Guide

## Overview

The application consists of two independently deployed components:

1. **Backend Services** - Phoenix, ElectricSQL, Proxy
2. **Frontend** - Static assets on CDN

## Prerequisites

- Production PostgreSQL database
- Backend hosting (Fly.io, AWS, or DigitalOcean)
- Frontend CDN (Cloudflare Pages or Netlify)
- Domain names configured
- Secrets management

## Backend Deployment

### Fly.io (Recommended for Phoenix)

1. Install Fly CLI:
```bash
curl -L https://fly.io/install.sh | sh
```

2. Login and create app:
```bash
fly auth login
fly launch
```

3. Set secrets:
```bash
fly secrets set \
  DATABASE_URL=postgresql://... \
  SECRET_KEY_BASE=$(mix phx.gen.secret) \
  GUARDIAN_SECRET_KEY=$(mix phx.gen.secret) \
  FRONTEND_URL=https://app.example.com
```

4. Deploy:
```bash
fly deploy
```

### Environment Variables

Required production environment variables:

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db

# Phoenix
SECRET_KEY_BASE=<generate-with-mix-phx.gen.secret>
PHX_HOST=api.example.com
PORT=4000

# CORS
FRONTEND_URL=https://app.example.com

# Electric
ELECTRIC_URL=http://electric:5133
ELECTRIC_WRITE_TO_PG_MODE=direct_writes

# Authentication
GUARDIAN_SECRET_KEY=<generate-secure-secret>
GUARDIAN_ISSUER=sertantai_controls
TOKEN_SIGNING_SECRET=<generate-secure-secret>

# Shape Tokens
SHAPE_TOKEN_TTL=3600
SHAPE_TOKEN_TYPE=Bearer
```

## Frontend Deployment

### Cloudflare Pages

1. Install Wrangler:
```bash
npm install -g wrangler
```

2. Login:
```bash
wrangler login
```

3. Build and deploy:
```bash
cd frontend
npm run build
wrangler pages deploy build --project-name=sertantai-controls
```

4. Set environment variables in Cloudflare dashboard:
```
PUBLIC_API_URL=https://api.example.com
PUBLIC_ELECTRIC_PROXY_URL=https://proxy.example.com
PUBLIC_ENV=production
```

### Netlify (Alternative)

1. Install Netlify CLI:
```bash
npm install -g netlify-cli
```

2. Login and deploy:
```bash
cd frontend
npm run build
netlify deploy --prod --dir=build
```

## Database Setup

### Migrations

Run migrations in production:

```bash
# Fly.io
fly ssh console -C "cd /app && bin/sertantai_controls eval 'SertantaiControls.Release.migrate'"

# Or via SSH
ssh production
cd /app
bin/sertantai_controls eval "SertantaiControls.Release.migrate"
```

### Backups

Set up automated daily backups:

- Fly.io: Automatic with Fly Postgres
- AWS: Use RDS automated backups
- DigitalOcean: Enable automated backups in dashboard

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
# Fly.io
fly releases
fly rollback <release-id>

# Manual
git revert <commit>
git push
```

### Frontend Rollback

```bash
# Cloudflare Pages
wrangler pages deployment list
wrangler pages deployment rollback <deployment-id>

# Netlify
netlify rollback
```

### Database Rollback

```bash
# SSH into server
cd /app
bin/sertantai_controls eval "SertantaiControls.Repo.rollback(SertantaiControls.Repo, 1)"
```

## SSL/TLS

Both Fly.io and Cloudflare Pages provide automatic SSL certificates.

Custom domains:
1. Add CNAME records pointing to deployment
2. Wait for SSL provisioning (automatic)

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

### Deployment Fails

Check logs:
```bash
fly logs
```

### Database Connection Issues

Verify connection string:
```bash
fly ssh console
printenv DATABASE_URL
```

### CORS Errors

Ensure `FRONTEND_URL` environment variable matches actual frontend domain.

## Additional Resources

- [Fly.io Docs](https://fly.io/docs/)
- [Cloudflare Pages Docs](https://developers.cloudflare.com/pages/)
- [Phoenix Deployment](https://hexdocs.pm/phoenix/deployment.html)
