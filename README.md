# Sertantai Controls

Real-time risk control management system using a novel 2x2 classification model based on time-since-last-touch and provider distance.

## Overview

Sertantai Controls implements an innovative approach to industrial risk control management by dynamically classifying controls into four quadrants:

- **Self** (Recent × Close): Controls touched recently by nearby providers
- **Specialist** (Distant × Close): Controls needing specialist attention from nearby providers
- **Service** (Recent × Remote): Recently serviced controls from remote providers
- **Strange** (Distant × Remote): High-risk controls - distant in time and provider network

Controls automatically move between quadrants based on:
1. **Time since last touched** - How long since the last interaction
2. **Provider distance** - Graph-based distance in the provider network

This enables predictive maintenance and proactive risk management.

## Tech Stack

- **Frontend**: SvelteKit + TypeScript + TanStack DB + ElectricSQL v1.0
- **Backend**: Elixir + Phoenix + Ash Framework 3.0
- **Database**: PostgreSQL 15+ with logical replication
- **Sync**: ElectricSQL HTTP Shape API
- **Quality**: Credo, Dialyzer, ESLint, Prettier, Vitest
- **CI/CD**: Git hooks + GitHub Actions

## Prerequisites

**Development Tools**:
- Docker & Docker Compose
- Elixir 1.16+ and Erlang/OTP 26+
- Node.js 20+ and npm/pnpm
- Make

**Note**: In development, all services including PostgreSQL run locally via Docker Compose. The `~/Desktop/infrastructure` project is for **production deployment only**.

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/shotleybuilder/sertantai-controls.git
cd sertantai-controls

# 2. Start all services with Docker Compose
docker-compose -f docker-compose.dev.yml up

# This starts: PostgreSQL, ElectricSQL, Phoenix backend, Vite dev server
```

Access the application:
- Frontend: http://localhost:5173
- Backend API: http://localhost:4000
- ElectricSQL: http://localhost:3000
- PostgreSQL: localhost:5435

### Manual Setup (without Docker)

**Backend:**
```bash
cd backend
mix deps.get
mix ash.setup              # Creates DB, runs migrations, seeds
mix phx.server
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

## Project Structure

```
sertantai-controls/
├── backend/                       # Phoenix + Ash backend
│   ├── lib/
│   │   ├── sertantai_controls/
│   │   │   ├── auth/              # User & Organization (read-only)
│   │   │   │   ├── user.ex
│   │   │   │   └── organization.ex
│   │   │   └── safety/            # Core domain resources
│   │   │       ├── control.ex     # Main control resource
│   │   │       ├── control_provider.ex
│   │   │       ├── provider_network.ex
│   │   │       ├── control_interaction.ex
│   │   │       ├── quadrant_classification.ex
│   │   │       ├── organizational_trace.ex
│   │   │       └── competency_record.ex
│   │   ├── api.ex                 # Ash Domain
│   │   └── repo.ex
│   ├── priv/
│   │   └── repo/
│   │       ├── migrations/        # Ash-generated migrations
│   │       └── seeds.exs          # Synthetic data (9 controls, 5 providers)
│   └── test/
│
├── frontend/                      # SvelteKit frontend
│   ├── src/
│   │   ├── routes/                # SvelteKit routes
│   │   ├── lib/                   # Shared utilities
│   │   └── test/                  # Vitest tests
│   ├── static/
│   └── vitest.config.ts
│
├── .github/
│   └── workflows/
│       └── ci.yml                 # GitHub Actions CI/CD
│
├── docs/
│   └── innovative_schema.md       # Schema design document
│
└── docker-compose.dev.yml         # Local development setup
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
