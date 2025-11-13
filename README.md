# Sertantai Controls

A modern, offline-first full-stack application built with Svelte, Phoenix, and ElectricSQL.

## Architecture

- **Frontend**: SvelteKit + TanStack DB + ElectricSQL client
- **Backend**: Elixir + Phoenix + Ash Framework + ElectricSQL
- **Database**: PostgreSQL (provided by infrastructure project)
- **Sync**: ElectricSQL with gatekeeper authentication
- **Deployment**: Backend on Fly.io/AWS, Frontend on Cloudflare Pages

## Key Features

- **Offline-First**: Full functionality without network connection via TanStack DB
- **Real-Time Sync**: ElectricSQL provides bidirectional sync with PostgreSQL
- **Sub-Millisecond Queries**: Differential dataflow powered by TanStack DB
- **Optimistic Updates**: Instant UI feedback with automatic rollback
- **Shape-Based Auth**: JWT tokens scoped to specific data shapes
- **Multi-Tenant**: Built-in organization-level data isolation

## Prerequisites

**Development Tools**:
- Docker & Docker Compose
- Elixir 1.16+ and Erlang/OTP 26+
- Node.js 20+ and npm/pnpm
- Make

**Note**: In development, all services including PostgreSQL run locally via Docker Compose. The `~/Desktop/infrastructure` project is for **production deployment only**.

## Quick Start

```bash
# 1. Install dependencies
cd ~/Desktop/sertantai-controls
make setup

# 2. Start development environment (includes PostgreSQL, Electric, Proxy, Backend, Frontend)
make dev

# 3. Run migrations
make migrate

# 4. Seed database (optional)
make seed
```

Access the application:
- Frontend: http://localhost:5173
- Backend API: http://localhost:4000
- Auth Proxy: http://localhost:3000

## Project Structure

```
sertantai-controls/
├── frontend/              # SvelteKit application
│   ├── src/
│   │   ├── lib/
│   │   │   ├── components/    # Svelte components
│   │   │   ├── stores/        # Auth & UI state
│   │   │   ├── db/            # TanStack DB collections & queries
│   │   │   └── electric/      # ElectricSQL client & sync
│   │   └── routes/            # SvelteKit routes
│   └── tests/                 # Vitest & Playwright tests
│
├── backend/               # Phoenix + Ash application
│   ├── lib/
│   │   ├── sertantai_controls/        # Business logic
│   │   │   ├── resources/             # Ash resources
│   │   │   ├── domains/               # Domain logic
│   │   │   └── electric/              # Electric integration
│   │   └── sertantai_controls_web/    # Web layer
│   │       ├── controllers/           # REST endpoints
│   │       │   ├── auth_controller.ex
│   │       │   └── gatekeeper_controller.ex
│   │       └── plugs/                 # Middleware
│   └── test/                          # ExUnit tests
│
├── proxy/                 # Authorizing proxy for Electric
├── docs/                  # Project documentation
└── database/              # Database migrations & seeds
```

## Development Workflow

### Common Commands

```bash
make setup       # Install dependencies
make dev         # Start all services
make stop        # Stop all services
make migrate     # Run database migrations
make rollback    # Rollback last migration
make seed        # Seed database
make test        # Run all tests
make lint        # Run linters
make format      # Format code
```

### Environment Variables

Copy `.env.example` files:
```bash
cp frontend/.env.example frontend/.env
cp backend/.env.example backend/.env
```

Edit as needed for your local setup.

### Database Migrations

```bash
# Create new migration
cd backend
mix ecto.gen.migration migration_name

# Run migrations
make migrate

# Rollback
make rollback
```

## Technology Stack

### Frontend
- Svelte 4.x / SvelteKit
- TypeScript 5.x
- TanStack DB (reactive store with differential dataflow)
- ElectricSQL client (real-time sync)
- TailwindCSS + DaisyUI
- Vite 5.x
- Vitest (unit tests)
- Playwright (E2E tests)

### Backend
- Elixir 1.16+
- Phoenix 1.7+
- Ash Framework 3.x
- AshAuthentication (auth)
- Guardian (JWT)
- Ecto 3.11+
- PostgreSQL 15+
- ElectricSQL

### Infrastructure
- Docker & Docker Compose
- PostgreSQL with logical replication
- ElectricSQL sync service
- Caddy (authorizing proxy)

## Authentication Flow

1. User logs in with credentials → Backend validates
2. Backend generates shape-scoped JWT token
3. Client requests data shape with token → Proxy validates
4. Proxy forwards authorized requests → Electric streams data
5. TanStack DB stores locally → UI updates reactively

## Testing

```bash
# Frontend tests
npm run test              # Unit tests (Vitest)
npm run test:coverage     # With coverage
npm run test:e2e          # E2E tests (Playwright)

# Backend tests
mix test                  # All tests
mix test --cover          # With coverage
mix test --only integration  # Integration tests only

# All tests
make test
```

## Deployment

### Production Infrastructure

This project deploys to the **~/Desktop/infrastructure** environment for production:

- **Backend**: Deployed as Docker container to shared infrastructure
  - Uses shared PostgreSQL instance (separate database: `sertantai_controls_prod`)
  - Uses shared Redis for caching
  - Routed via Nginx reverse proxy with subdomain (e.g., `app.yourdomain.com`)
  - Automatic SSL via Let's Encrypt

- **Frontend**: Deployed separately to CDN (Cloudflare Pages / Netlify)
  - Static site generation
  - Global edge caching
  - Automatic preview deployments for PRs
  - Points to production backend API

### Deployment Process

1. **Backend**: Add service to `~/Desktop/infrastructure/docker/docker-compose.yml`
2. **Frontend**: Deploy via Wrangler/Netlify CLI to CDN
3. **Database**: Migrations run automatically on backend startup

See [docs/deployment.md](docs/deployment.md) for detailed instructions.

## Documentation

- [Architecture](docs/architecture.md) - System design and data flow
- [API Documentation](docs/api.md) - REST endpoints and authentication
- [Development Guide](docs/development.md) - Coding standards and contribution guidelines
- [Deployment Guide](docs/deployment.md) - Production deployment procedures
- [Blueprint](sertantai-controls-blueprint.md) - Comprehensive project blueprint

## Contributing

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make changes and test thoroughly
3. Commit with descriptive messages
4. Push and create a pull request

## License

[Your License Here]

## Support

For issues and questions, please open a GitHub issue.
