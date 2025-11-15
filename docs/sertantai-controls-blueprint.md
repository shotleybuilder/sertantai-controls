# Sertantai-Controls Project Blueprint v6.0

**Completion Status**: ✅ Initial Commit Complete - CI/CD & Quality Tools Configured (15% implemented)

## Project Overview

Real-time risk control management system using a novel **2x2 classification model** based on time-since-last-touch and provider distance.

A full-stack application consisting of:
- **Frontend**: SvelteKit + TypeScript + TanStack DB + ElectricSQL v1.0 HTTP Shape API
- **Backend**: Elixir + Phoenix + Ash Framework 3.0 with 8 domain resources
- **Database**: PostgreSQL 15+ with comprehensive seed data
- **CI/CD**: Git hooks (pre-commit/pre-push) + GitHub Actions

**Data Architecture**: TanStack DB provides local persistence and lightning-fast UI through differential dataflow, enabling sub-millisecond queries across normalized collections. ElectricSQL v1.0 handles real-time sync using the new HTTP Shape API with built-in authentication, creating a truly offline-first, reactive application.

## Multi-App Architecture (v5.0 UPDATE)

**IMPORTANT ARCHITECTURAL DECISION**: This application is part of a multi-app ecosystem with **centralized authentication**.

### Ecosystem Structure

```
sertantai-auth (auth.yourdomain.com)
  ├─ Owns: users, organizations, sessions tables
  ├─ Handles: login, registration, password reset, OAuth
  ├─ Issues: JWTs with org_id, user_id, roles claims
  └─ Database: Primary source of truth for auth data

sertantai-controls (controls.yourdomain.com)
  ├─ Syncs: users, organizations tables via ElectricSQL (read-only)
  ├─ Validates: JWTs from sertantai-auth
  ├─ Owns: domain-specific tables (equipment, sensors, etc.)
  └─ Database: Shared Postgres with sertantai-auth

sertantai-[app2], sertantai-[app3], etc.
  └─ Same pattern as controls
```

### Shared Database Strategy

All apps connect to the **same PostgreSQL instance** but:
- **sertantai-auth** has write access to `users`, `organizations`, `sessions`
- **Other apps** have read-only access to auth tables (via Electric sync)
- **Each app** owns its domain-specific tables

### ElectricSQL Sync Pattern

```elixir
# In sertantai-controls backend
# User/Org data synced from sertantai-auth (read-only)
defmodule SertantaiControls.Auth.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql, AshJsonApi]

  postgres do
    table "users"  # Owned by sertantai-auth
    repo SertantaiControls.Repo
  end

  # Read-only resource - no create/update/destroy actions
  actions do
    read :read
    read :by_id
  end
end
```

### JWT Validation Flow

1. User logs in via `sertantai-auth` → receives JWT
2. User accesses `sertantai-controls` with JWT in header
3. Backend validates JWT signature and claims
4. Frontend syncs user/org data from local Electric cache
5. All operations scoped to `org_id` from JWT

### Benefits of This Architecture

- ✅ **Single Sign-On**: One login works across all apps
- ✅ **Fast Local Access**: User data cached locally via Electric
- ✅ **Independent Deployment**: Each app deploys separately
- ✅ **Centralized User Management**: One place to manage users/orgs
- ✅ **Multi-tenancy**: Organization-level data isolation built-in
- ✅ **Offline-First**: Auth data synced and available offline

## Directory Structure

```
sertantai-controls/
├── .git/
├── .github/
│   └── workflows/
│       ├── frontend-ci.yml
│       ├── backend-ci.yml
│       └── integration-tests.yml
├── .gitignore
├── README.md
├── docker-compose.yml
├── docker-compose.dev.yml
├── Makefile
│
├── frontend/
│   ├── .gitignore
│   ├── package.json
│   ├── vite.config.js
│   ├── svelte.config.js
│   ├── tsconfig.json
│   ├── vitest.config.js
│   ├── playwright.config.js
│   ├── .env.example
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── src/
│   │   ├── lib/
│   │   │   ├── components/
│   │   │   ├── stores/
│   │   │   │   └── auth.ts           # Auth state & token mgmt
│   │   │   ├── utils/
│   │   │   ├── db/
│   │   │   │   ├── client.ts          # TanStack DB instance
│   │   │   │   ├── collections.ts     # Collection definitions
│   │   │   │   ├── queries.ts         # Live queries
│   │   │   │   └── mutations.ts       # Optimistic mutations
│   │   │   └── electric/
│   │   │       ├── client.ts          # ElectricSQL client
│   │   │       ├── schema.ts          # Type-safe schema
│   │   │       └── sync.ts            # Sync integration
│   │   ├── routes/
│   │   ├── app.html
│   │   └── app.css
│   ├── static/
│   ├── tests/
│   │   ├── unit/
│   │   ├── integration/
│   │   └── e2e/
│   └── public/
│
├── backend/
│   ├── .gitignore
│   ├── mix.exs (✅ with Credo, Dialyzer, mix_audit)
│   ├── mix.lock
│   ├── .formatter.exs
│   ├── .credo.exs (✅ configured)
│   ├── .dialyzer_ignore.exs
│   ├── .env.example
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── config/
│   │   ├── config.exs
│   │   ├── dev.exs
│   │   ├── test.exs
│   │   ├── prod.exs
│   │   └── runtime.exs
│   ├── lib/
│   │   ├── sertantai_controls/
│   │   │   ├── api.ex (Ash.Domain)
│   │   │   ├── application.ex
│   │   │   ├── repo.ex
│   │   │   ├── auth/ (User, Organization - read-only resources)
│   │   │   ├── safety/ (Control, ControlProvider, etc. - domain resources)
│   │   │   └── electric/
│   │   │       └── sync.ex
│   │   └── sertantai_controls_web/
│   │       ├── endpoint.ex
│   │       ├── router.ex
│   │       ├── controllers/
│   │       │   └── page_controller.ex
│   │       ├── components/
│   │       │   ├── core_components.ex
│   │       │   └── layouts.ex
│   │       └── gettext.ex
│   ├── priv/
│   │   ├── repo/
│   │   │   ├── migrations/ (✅ 8 resources migrated)
│   │   │   └── seeds.exs (✅ comprehensive seed data)
│   │   ├── plts/ (Dialyzer PLT files)
│   │   ├── static/
│   │   └── gettext/
│   └── test/
│       ├── sertantai_controls/
│       ├── sertantai_controls_web/
│       ├── support/
│       │   ├── conn_case.ex
│       │   ├── data_case.ex
│       │   └── fixtures.ex
│       └── test_helper.exs
│
├── database/
│   ├── init.sql
│   └── electric/
│       └── migrations/
│
└── docs/
    ├── architecture.md
    ├── api.md
    ├── deployment.md
    └── development.md
```

## Git Setup

### Initial Repository Setup

```bash
# Initialize repository
git init
git branch -M main

# Configure Git settings
git config core.autocrlf input
git config pull.rebase false
```

### Branch Strategy

- **main**: Production-ready code, protected branch
- **develop**: Integration branch for features
- **feature/**: Feature branches (e.g., feature/user-auth)
- **fix/**: Bug fix branches
- **release/**: Release preparation branches

### Branch Protection Rules

For `main` branch:
- Require pull request reviews (min 1 approval)
- Require status checks to pass
- Require branches to be up to date
- No force pushes
- No deletions

### .gitignore (Root)

```
# Environment variables
.env
.env.local
.env.*.local

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Logs
*.log
logs/

# Dependencies
node_modules/
deps/
_build/

# Build outputs
dist/
build/
.svelte-kit/

# Test coverage
coverage/
.nyc_output/

# Docker volumes
volumes/
```

## CI/CD Pipeline (Shift-Left Implementation) ✅

### Git Hooks (Implemented)

#### Pre-Commit Hook (.git/hooks/pre-commit) ✅
**7 Quality Checks** run locally before commit:

**Backend Checks**:
1. **Code Formatting**: `mix format --check-formatted` on staged Elixir files
2. **Compilation**: `mix compile --force --warnings-as-errors`
3. **Credo Static Analysis**: `mix credo --only design,consistency`
4. **Ash Codegen Check**: `mix ash.codegen --check`

**Frontend Checks**:
5. **Prettier Formatting**: `npm run format:check` on staged files
6. **ESLint**: `npm run lint` with browser/Node.js globals configured
7. **TypeScript Check**: `npm run check` (svelte-check)

**Non-Blocking Items**: Credo AliasUsage warnings (low priority, exit_status 0)

**Override**: `git commit --no-verify` (use sparingly)

#### Pre-Push Hook (.git/hooks/pre-push) ✅
**5 Expensive Checks** run before push to remote:

**Backend Checks**:
1. **Dialyzer Type Checking**: `mix dialyzer --format github` (warnings non-blocking)
2. **Security Audit**: `mix deps.audit` (blocking on vulnerabilities)
3. **Unused Dependencies**: `mix deps.unlock --check-unused` (non-blocking warning)
4. **Backend Test Suite**: `mix test --exclude integration`

**Frontend Checks**:
5. **Frontend Test Suite**: `npm run test:run` (no-test-files non-blocking)

**Non-Blocking Items**:
- Dialyzer warnings (logged but don't fail)
- Missing frontend test files (warning only)
- Unused dependencies (warning only)

**Override**: `git push --no-verify` (use sparingly)

### GitHub Actions CI Pipeline (.github/workflows/ci.yml) ✅

**3 Jobs** running in parallel:

#### Job 1: backend-checks
1. Setup Elixir (1.18.1) + Erlang (OTP 27.2)
2. Cache deps and _build
3. Install dependencies
4. Check formatting
5. Compile with warnings as errors
6. Run Credo
7. Check Ash codegen
8. Run Dialyzer
9. Security audit
10. Check unused dependencies
11. Run backend tests

#### Job 2: frontend-checks
1. Setup Node.js 20
2. Cache node_modules
3. Install dependencies
4. Check formatting (Prettier)
5. Run ESLint
6. Type check (svelte-check)
7. Run tests (Vitest)
8. Build production bundle

#### Job 3: integration-tests
- **Depends on**: backend-checks, frontend-checks
- Runs integration tests (currently placeholder)

**Triggers**: Push to any branch, Pull requests

**Future Enhancements**:
- [ ] E2E tests with Playwright
- [ ] Security scanning (npm audit, Sobelow)
- [ ] Docker image build and push
- [ ] Deploy preview environments

### Deployment Pipeline

#### Backend Deployment

**Environments**:
- **Development**: Auto-deploy from `develop` branch
- **Staging**: Auto-deploy from `release/*` branches
- **Production**: Manual approval required from `main` branch

**Backend Services** (Phoenix + Electric + Proxy):
- Deployed to Fly.io / AWS / DigitalOcean
- Docker container build and push
- Database migrations run automatically
- Health check verification
- Rollback capability

#### Frontend Deployment (Separate Pipeline)

**Static Site Deployment**:
- **Cloudflare Pages** (Recommended):
  ```yaml
  # .github/workflows/frontend-deploy.yml
  - Build: npm run build (outputs to frontend/build)
  - Deploy: wrangler pages deploy frontend/build
  - Environment variables injected per environment
  - Automatic preview deployments for PRs
  ```

- **Netlify Alternative**:
  ```yaml
  - Build: npm run build
  - Deploy: netlify deploy --prod --dir=frontend/build
  - Environment variables from netlify.toml or UI
  ```

**Environments**:
- **Development**: Auto-deploy from `develop` branch → dev.example.com
- **Staging**: Auto-deploy from `release/*` branches → staging.example.com
- **Production**: Auto-deploy from `main` branch (after approval) → app.example.com

**Key Considerations**:
- Frontend and backend deploy independently
- Frontend env vars point to correct backend API URLs per environment
- CORS configuration must match frontend domains
- CDN cache invalidation on deployment
- Atomic deployments (rollback to previous version if needed)

## Testing Strategy

### Frontend Testing

#### Unit Tests (Vitest)
- Component logic testing
- TanStack DB collection tests
  - Schema validation
  - Query logic correctness
  - Mutation behavior
  - Optimistic update scenarios
- Store/state management testing
- Utility function testing
- Coverage target: 80%

#### Integration Tests
- TanStack DB ↔ ElectricSQL sync integration
  - Shape subscription handling
  - Bidirectional data flow
  - Conflict resolution
  - Offline queue processing
- Cross-collection live queries
- Optimistic mutation rollback scenarios
- Multi-component workflows

#### E2E Tests (Playwright)
- Critical user journeys with optimistic updates
- Collaborative multi-client scenarios
- Offline → online transition workflows
- Cross-browser testing (Chromium, Firefox, WebKit)
- Visual regression tests
- Performance benchmarks (query response times)

#### Test Commands ✅
```bash
npm run test           # Run unit tests (Vitest watch mode)
npm run test:ui        # Vitest UI mode
npm run test:run       # Run once and exit
npm run test:coverage  # Generate coverage report
```

**Note**: E2E tests with Playwright not yet configured

### Backend Testing

#### Unit Tests (ExUnit)
- Resource/domain logic
- Context functions
- Helper utilities
- Coverage target: 80%

#### Integration Tests
- Phoenix controller/LiveView tests
- API endpoint tests
- GraphQL query/mutation tests

#### Property-Based Tests (StreamData)
- Complex business logic validation
- Edge case discovery

#### Database Tests
- Migration tests
- Constraint validation
- ElectricSQL trigger tests

#### Test Commands
```bash
mix test                    # Run all tests
mix test --cover            # With coverage
mix test.watch              # Watch mode
mix test --only integration # Integration tests only
```

## Server Infrastructure

### Development Environment

#### Local Services (No Infrastructure Dependency)

**Note**: Development runs entirely locally with Docker Compose. The `~/Desktop/infrastructure` project is **production-only** and not required for local development.

#### Docker Compose Services

**docker-compose.dev.yml** (all services self-contained):
- **postgres**: Local PostgreSQL 15 with logical replication enabled
- **electric**: ElectricSQL v1.0 sync service with built-in HTTP API
- **backend**: Phoenix application
- **frontend**: Vite dev server with HMR

**Note**: ElectricSQL v1.0 has built-in authentication via HTTP headers, no separate proxy service needed.

#### Service Configuration

```yaml
# PostgreSQL (local development container)
Host: localhost (postgres within Docker network)
Port: 5432 (exposed to host)
Database: sertantai_controls_dev
User: postgres
Password: postgres (dev only)
Logical replication: enabled (wal_level=logical)
Volume: postgres_data (persisted)

# ElectricSQL v1.0
Port: 5133 (HTTP Shape API)
Connected to local postgres container
Authentication via HTTP headers (Authorization: Bearer <token>)
Endpoint: GET /v1/shape?table=<table>&where=<filter>

# Backend (Phoenix)
Port: 4000
Environment: development
Hot reload enabled
CORS enabled via Plug.Cors (allows frontend :5173)
Connects to local postgres container

# Frontend (Vite)
Port: 5173
HMR enabled
Connects to proxy :3000 for Electric shapes
API requests to backend :4000 (CORS-enabled)
```

#### Example docker-compose.dev.yml

```yaml
version: '3.8'

networks:
  sertantai_network:
    driver: bridge

services:
  # PostgreSQL database (local development)
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: sertantai_controls_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - sertantai_network
    command:
      - "postgres"
      - "-c"
      - "wal_level=logical"
      - "-c"
      - "max_replication_slots=10"
      - "-c"
      - "max_wal_senders=10"

  # ElectricSQL v1.0 sync service (built-in auth)
  electric:
    image: electricsql/electric:latest
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/sertantai_controls_dev
      LOGICAL_PUBLISHER_HOST: postgres
      LOGICAL_PUBLISHER_PORT: 5432
      AUTH_MODE: insecure  # Dev only - use JWT in production
    ports:
      - "5133:5133"
    networks:
      - sertantai_network
    depends_on:
      postgres:
        condition: service_healthy

  # Phoenix backend
  backend:
    build: ./backend
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/sertantai_controls_dev
      FRONTEND_URL: http://localhost:5173
      ELECTRIC_URL: http://electric:5133
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      MIX_ENV: dev
    ports:
      - "4000:4000"
    volumes:
      - ./backend:/app
      - backend_build:/app/_build
      - backend_deps:/app/deps
    networks:
      - sertantai_network
    depends_on:
      postgres:
        condition: service_healthy
      electric:
        condition: service_started
    command: mix phx.server

  # Vite dev server
  frontend:
    build: ./frontend
    environment:
      PUBLIC_API_URL: http://localhost:4000
      PUBLIC_ELECTRIC_URL: http://localhost:5133
    ports:
      - "5173:5173"
    volumes:
      - ./frontend:/app
      - frontend_node_modules:/app/node_modules
    networks:
      - sertantai_network
    command: npm run dev

volumes:
  postgres_data:
  backend_build:
  backend_deps:
  frontend_node_modules:
```

### Production Environment

#### Infrastructure Project (~/Desktop/infrastructure)

**Production deployment uses the shared infrastructure project** which provides:
- **Shared PostgreSQL 16**: Multiple databases on single instance
  - `ehs_enforcement_prod`
  - `baserow`
  - `n8n`
  - `sertantai_controls_prod` (this project)
- **Shared Redis 7**: Caching and sessions
- **Nginx Reverse Proxy**: Subdomain routing with automatic SSL
- **Centralized Management**: Single deployment, unified backups

#### Backend Services (Added to Infrastructure)

Backend services are added to `~/Desktop/infrastructure/docker/docker-compose.yml`:

1. **Sertantai Controls Backend (Phoenix)**
   - Service name: `sertantai-controls`
   - Connects to shared `postgres` service
   - Uses shared `redis` for caching
   - Database: `sertantai_controls_prod`
   - Nginx subdomain: `app.yourdomain.com` → `sertantai-controls:4000`
   - Gatekeeper endpoints at `/api/gatekeeper/*`
   - Health check: `/health`

2. **ElectricSQL Service**
   - Service name: `sertantai-controls-electric`
   - Connects to shared `postgres` with logical replication
   - Database: `sertantai_controls_prod`
   - Not publicly accessible (internal network only)

3. **Authorizing Proxy**
   - Service name: `sertantai-controls-proxy`
   - Validates JWT tokens
   - Forwards to Electric after validation
   - Can be deployed as part of infrastructure or to edge

#### Frontend Deployment (Separate - CDN)

**Hosting Options**:

- **Option A: Cloudflare Pages** (Recommended - Free, Open Source CLI)
  - Free tier: Unlimited sites, bandwidth, requests
  - Global CDN with 300+ edge locations
  - Automatic SSL/TLS
  - Git integration for auto-deployment
  - Deploy with: `wrangler pages deploy`

- **Option B: Netlify** (Free tier available)
  - 100GB bandwidth/month free
  - Global CDN
  - Automatic HTTPS
  - Git-based deployment
  - Open source CLI: `netlify deploy`

- **Option C: Vercel** (Free for personal/hobby projects)
  - Global edge network
  - Automatic SSL
  - Git integration
  - Open source CLI: `vercel deploy`

**Deployment Configuration**:
- Static build output from `frontend/build/`
- Environment variables point to production backend
- CORS must allow frontend domain
- Independent deployment from backend
- Atomic deployments with instant rollback

#### Monitoring & Observability

- **Application Monitoring**: AppSignal or New Relic
- **Logging**: Centralized logging (ELK stack or Datadog)
- **Metrics**: Prometheus + Grafana
- **Error Tracking**: Sentry
- **Uptime Monitoring**: UptimeRobot or Pingdom

## Technology Stack Details

### Frontend

**Core**:
- Svelte 4.x / SvelteKit
- TypeScript 5.x
- Vite 5.x

**Data & State**:
- **TanStack DB**: Reactive client store with differential dataflow
  - Local persistence with IndexedDB
  - Collections for normalized data storage
  - Live queries with sub-millisecond performance
  - Joins, filters, and aggregates across collections
  - Optimistic mutations with automatic rollback
  - Fine-grained reactivity to minimize re-renders
- **ElectricSQL client**: Real-time sync with PostgreSQL backend
  - Shape-based subscriptions
  - Bidirectional sync with conflict resolution
  - Integrates with TanStack DB collections
- **Svelte stores**: Ephemeral UI state only

**UI/Styling**:
- TailwindCSS
- DaisyUI or Skeleton UI
- Svelte animations

**Testing**:
- Vitest
- Playwright
- Testing Library (Svelte)

**Code Quality** ✅:
- ESLint (with @typescript-eslint, eslint-plugin-svelte)
- Prettier (with prettier-plugin-svelte)
- TypeScript strict mode
- Vitest (testing framework with jsdom)

### Backend

**Core**:
- Elixir 1.16+
- Phoenix 1.7+
- Ash Framework 3.x

**Database**:
- PostgreSQL 15+
- Ecto 3.11+
- ElectricSQL

**API**:
- Phoenix REST endpoints
- Absinthe (GraphQL) - optional
- JSON API serialization
- **Plug.Cors**: CORS middleware for cross-origin requests
  - Development: Allow localhost:5173 (Vite dev server)
  - Production: Allow frontend CDN domain

**Auth**:
- AshAuthentication
- Guardian (JWT)
- Argon2 (password hashing)

**Code Quality** ✅:
- Credo (v1.7, configured for Ash Framework)
- Dialyzer (v1.4, with PLT caching)
- mix_audit (v2.1, security vulnerability scanning)
- ExUnit (built-in testing)

### Backend CORS Configuration

#### Development Setup

```elixir
# mix.exs - Add dependency
defp deps do
  [
    {:plug_cors, "~> 1.5"},
    # ... other deps
  ]
end
```

```elixir
# lib/sertantai_controls_web/endpoint.ex
defmodule SertantaiControlsWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :sertantai_controls

  # CORS must be plugged before other plugs
  if Mix.env() == :dev do
    plug Corsica,
      origins: [
        "http://localhost:5173",    # Vite dev server
        "http://localhost:3000",    # Auth proxy
        ~r{^https?://.*\.local$}    # Local domain variants
      ],
      allow_headers: [
        "accept",
        "authorization",
        "content-type",
        "origin"
      ],
      allow_methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      allow_credentials: true,
      max_age: 600
  end

  # ... rest of endpoint configuration
end
```

#### Production Setup

```elixir
# config/runtime.exs
if config_env() == :prod do
  frontend_url = System.get_env("FRONTEND_URL") || "https://app.example.com"

  config :sertantai_controls, SertantaiControlsWeb.Endpoint,
    cors_origins: [frontend_url]
end
```

```elixir
# lib/sertantai_controls_web/endpoint.ex
defmodule SertantaiControlsWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :sertantai_controls

  # Production CORS from runtime config
  if Mix.env() == :prod do
    plug Corsica,
      origins: Application.get_env(:sertantai_controls, __MODULE__)[:cors_origins] || [],
      allow_headers: [
        "accept",
        "authorization",
        "content-type",
        "origin"
      ],
      allow_methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      allow_credentials: true,
      max_age: 86400  # 24 hours
  end

  # ... rest of endpoint configuration
end
```

## TanStack DB + ElectricSQL Integration

### Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Svelte UI Layer                   │
│            (Components, Routes, Stores)             │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│                  TanStack DB                        │
│  ┌──────────────────────────────────────────────┐  │
│  │  Collections (Normalized, Type-Safe)         │  │
│  ├──────────────────────────────────────────────┤  │
│  │  Live Queries (Differential Dataflow)        │  │
│  ├──────────────────────────────────────────────┤  │
│  │  Optimistic Mutations (Instant Updates)      │  │
│  ├──────────────────────────────────────────────┤  │
│  │  IndexedDB (Local Persistence)               │  │
│  └──────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│              ElectricSQL Client                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  Shape Subscriptions (with JWT tokens)       │  │
│  ├──────────────────────────────────────────────┤  │
│  │  Conflict Resolution                         │  │
│  ├──────────────────────────────────────────────┤  │
│  │  Websocket Sync Protocol                     │  │
│  └──────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│      ElectricSQL v1.0 Sync Service (HTTP API)      │
│    Built-in authentication via HTTP headers         │
│         (Logical Replication Stream)                │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│    PostgreSQL + Phoenix/Ash Backend                 │
│  ┌──────────────────────────────────────────────┐  │
│  │  Gatekeeper Endpoints (Auth + Token Gen)     │  │
│  ├──────────────────────────────────────────────┤  │
│  │  Business Logic & Resources                  │  │
│  ├──────────────────────────────────────────────┤  │
│  │  Source of Truth Database                    │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### Data Flow Patterns

#### 1. Initial Load & Sync Setup
```typescript
// Initialize TanStack DB
const db = createDB({
  adapter: new IndexedDBAdapter('sertantai_controls'),
  collections: {
    users: UserCollection,
    projects: ProjectCollection,
    tasks: TaskCollection
  }
});

// Initialize Electric and sync to TanStack DB
const electric = await initElectric();
const shape = await electric.db.users.sync({
  // Shape definition
  where: { tenant_id: currentTenant.id }
});

// Pipe Electric data into TanStack DB collections
shape.subscribe((rows) => {
  db.collections.users.load(rows);
});
```

#### 2. Optimistic Writes (Instant UI Updates)
```typescript
// User clicks "Create Task" - instant UI feedback
await db.collections.tasks.create({
  id: generateId(),
  title: 'New Task',
  status: 'pending',
  created_at: new Date()
}, {
  optimistic: true  // Shows immediately in UI
});

// TanStack DB automatically:
// 1. Updates local collections instantly
// 2. Fires reactive queries
// 3. Updates UI with new data
// 4. Queues write to Electric/backend
// 5. Reconciles when backend confirms
// 6. Rolls back if backend rejects
```

#### 3. Live Queries (Sub-millisecond)
```typescript
// Define reactive query across collections
const activeTasksQuery = db.liveQuery(() =>
  db.collections.tasks
    .filter(task => task.status !== 'completed')
    .join(db.collections.users, 'assigned_to', 'id')
    .select({
      task_id: 'tasks.id',
      task_title: 'tasks.title',
      user_name: 'users.name',
      user_avatar: 'users.avatar'
    })
    .orderBy('tasks.created_at', 'desc')
);

// Use in Svelte component - auto-updates on any change
$: activeTasks = activeTasksQuery.results;
```

#### 4. Conflict Resolution
- **Strategy**: Last-write-wins with vector clocks
- **Handled by**: ElectricSQL automatically
- **TanStack DB role**: Accepts resolved state from Electric
- **User notification**: Optional conflict callback for critical data

### Performance Characteristics

**TanStack DB Benefits**:
- **Query Speed**: Sub-millisecond queries across collections (differential dataflow)
- **UI Responsiveness**: Instant optimistic updates, zero perceived latency
- **Fine-grained Reactivity**: Only affected components re-render
- **Normalized Storage**: No data duplication, efficient updates
- **Offline Support**: Full functionality without network connection

**ElectricSQL Benefits**:
- **Real-time Sync**: Changes propagate to all clients within ms
- **Selective Sync**: Only sync relevant data (shapes)
- **Conflict Resolution**: Automatic CRDT-based merging
- **Type Safety**: Generated TypeScript types from schema

### Integration Patterns

#### Pattern 1: Read-Heavy Dashboards
```typescript
// Multiple live queries, zero backend calls after initial sync
const dashboard = {
  stats: db.liveQuery(() => db.collections.tasks.aggregate()),
  recentTasks: db.liveQuery(() => db.collections.tasks.recent()),
  teamMembers: db.liveQuery(() => db.collections.users.active())
};
// All queries update automatically, sub-ms performance
```

#### Pattern 2: Collaborative Editing
```typescript
// Optimistic local edits, real-time sync to collaborators
async function updateDocument(docId, changes) {
  await db.collections.documents.update(docId, changes, {
    optimistic: true  // Instant local update
  });
  // Electric syncs to other clients automatically
}
```

#### Pattern 3: Offline-First Mobile
```typescript
// All operations work offline
await db.collections.tasks.create(newTask);  // Works offline
const tasks = await db.collections.tasks.all();  // Works offline

// When online, Electric syncs automatically
electric.on('connected', () => {
  // Queued changes sync to backend
  // Remote changes sync to local
});
```

### Testing TanStack DB Integration

#### Unit Tests
- Collection schema validation
- Query logic correctness
- Mutation behavior
- Optimistic update rollback scenarios

#### Integration Tests
- TanStack DB ↔ ElectricSQL sync
- Conflict resolution scenarios
- Offline queue handling
- Cross-collection query accuracy

#### E2E Tests
- Full user workflows with optimistic updates
- Multi-client sync scenarios
- Offline → online transition
- Performance benchmarks (query speed)

## Authentication: Multi-App with Centralized Auth (v5.0 UPDATE)

### Overview

**Authentication is handled by `sertantai-auth`**, not this app. This app:
1. **Validates** JWTs issued by `sertantai-auth`
2. **Syncs** user/org data from shared database (read-only via Electric)
3. **Uses** JWT claims (`org_id`, `user_id`, `roles`) for authorization
4. **Generates** shape-scoped tokens for ElectricSQL after JWT validation

### Multi-App Authentication Flow

```
┌─────────┐         ┌──────────────┐         ┌──────────────┐
│ Client  │         │ sertantai-   │         │ sertantai-   │
│         │         │    auth      │         │  controls    │
└────┬────┘         └──────┬───────┘         └──────┬───────┘
     │                     │                         │
     │ 1. Login            │                         │
     │ ─────────────────> │                         │
     │                     │                         │
     │ 2. JWT (org_id,     │                         │
     │    user_id, roles)  │                         │
     │ <───────────────── │                         │
     │                     │                         │
     │ 3. Request with JWT │                         │
     │ ────────────────────────────────────────────>│
     │                     │                         │
     │                     │ 4. Validate JWT         │
     │                     │    (shared secret)      │
     │                     │ 5. Read user/org from   │
     │                     │    Electric cache       │
     │                     │ 6. Check permissions    │
     │                     │                         │
     │ 7. Generate shape token │                     │
     │    (for Electric sync)  │                     │
     │ <───────────────────────────────────────────│
     │                     │                         │
     │                                        ┌──────────────┐
     │                                        │ Auth Proxy   │
     │                                        └──────┬───────┘
     │                                               │
     │ 8. Request shape with shape token            │
     │ ──────────────────────────────────────────> │
     │                                               │
     │                      9. Validate shape token │
     │                     10. Verify org_id filter │
     │                                               │
     │                                        ┌──────────────┐
     │                                        │  ElectricSQL │
     │                                        └──────┬───────┘
     │                                               │
     │                     11. Forward if authorized│
     │                      ─────────────────────> │
     │                                               │
     │ 12. Stream shape data (org-scoped)           │
     │ <──────────────────────────────────────────────────── │
     │                     │                         │
```

### Configuration Requirements

#### Shared JWT Secret

All apps must use the same JWT secret to validate tokens from `sertantai-auth`:

```elixir
# config/runtime.exs (both sertantai-auth and sertantai-controls)
config :joken, default_signer: System.get_env("SHARED_JWT_SECRET")
```

#### Database Connection

```elixir
# config/dev.exs
config :sertantai_controls, SertantaiControls.Repo,
  database: System.get_env("DATABASE_URL"),
  # Same database as sertantai-auth!
  pool_size: 10
```

### Backend Implementation (Phoenix/Ash)

#### 1. JWT Validation Plug

```elixir
# lib/sertantai_controls_web/plugs/auth_plug.ex
defmodule SertantaiControlsWeb.AuthPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case validate_token(token) do
          {:ok, claims} ->
            conn
            |> assign(:current_user_id, claims["user_id"])
            |> assign(:current_org_id, claims["org_id"])
            |> assign(:user_roles, claims["roles"])

          {:error, _reason} ->
            conn
            |> put_status(:unauthorized)
            |> Phoenix.Controller.json(%{error: "Invalid token"})
            |> halt()
        end

      _ ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "Missing authorization header"})
        |> halt()
    end
  end

  defp validate_token(token) do
    # Validates JWT from sertantai-auth using shared secret
    Joken.verify(token, Joken.Signer.parse_config(:default_signer))
  end
end
```

#### 2. Read-Only Auth Resources

```elixir
# lib/sertantai_controls/auth/user.ex
defmodule SertantaiControls.Auth.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi]

  postgres do
    table "users"  # Owned by sertantai-auth
    repo SertantaiControls.Repo
  end

  # READ-ONLY: No create/update/destroy actions
  actions do
    defaults [:read]

    read :by_id do
      get? true
      argument :id, :uuid, allow_nil?: false
      filter expr(id == ^arg(:id))
    end

    read :by_org do
      argument :org_id, :uuid, allow_nil?: false
      filter expr(organization_id == ^arg(:org_id))
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :string, allow_nil?: false
    attribute :name, :string
    attribute :organization_id, :uuid, allow_nil?: false

    timestamps()
  end

  relationships do
    belongs_to :organization, SertantaiControls.Auth.Organization
  end
end
```

#### 3. Shape Token Generation (Gatekeeper Endpoints)

```elixir
# lib/sertantai_controls_web/controllers/gatekeeper_controller.ex
defmodule SertantaiControlsWeb.GatekeeperController do
  use SertantaiControlsWeb, :controller

  # POST /api/gatekeeper/users
  # Generates shape-scoped JWT for users table
  def authorize_shape(conn, %{"table" => table, "params" => shape_params}) do
    user = conn.assigns.current_user

    # 1. Validate user has permission to access this shape
    with {:ok, authorized_params} <- authorize_user_for_shape(user, table, shape_params),
         # 2. Generate shape definition
         shape_def = build_shape_definition(table, authorized_params),
         # 3. Create JWT with shape claim
         {:ok, token, _claims} <- encode_shape_token(shape_def, user) do

      json(conn, %{
        token: token,
        shape: shape_def,
        expires_in: 3600  # 1 hour
      })
    else
      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Not authorized for this data shape"})
    end
  end

  defp authorize_user_for_shape(user, "tasks", params) do
    # Business logic: Users can only access their org's tasks
    if user.organization_id do
      {:ok, Map.put(params, :organization_id, user.organization_id)}
    else
      {:error, :unauthorized}
    end
  end

  defp build_shape_definition(table, params) do
    %{
      table: table,
      where: params.where || "",
      columns: params.columns,
      replica: params.replica || "default"
    }
  end

  defp encode_shape_token(shape_def, user) do
    claims = %{
      "sub" => user.id,
      "shape" => shape_def,
      "exp" => System.system_time(:second) + 3600
    }

    Guardian.encode_and_sign(user, claims, token_type: "shape")
  end
end
```

#### 2. User Authentication (AshAuthentication)

```elixir
# lib/sertantai_controls/accounts/user.ex
defmodule SertantaiControls.Accounts.User do
  use Ash.Resource,
    extensions: [AshAuthentication]

  authentication do
    api SertantaiControls.Accounts

    strategies do
      password :password do
        identity_field :email
        hashed_password_field :hashed_password
      end
    end

    tokens do
      enabled? true
      token_resource SertantaiControls.Accounts.Token
      signing_secret fn _, _ ->
        Application.get_env(:sertantai_controls, :token_signing_secret)
      end
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :string, allow_nil?: false
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :organization_id, :uuid
  end

  relationships do
    belongs_to :organization, SertantaiControls.Accounts.Organization
  end
end
```

### Frontend Implementation (Svelte)

#### 1. Authentication Store

```typescript
// src/lib/stores/auth.ts
import { writable } from 'svelte/store';

interface AuthState {
  user: User | null;
  accessToken: string | null;
  shapeTokens: Map<string, ShapeToken>;
}

interface ShapeToken {
  token: string;
  shape: ShapeDefinition;
  expiresAt: Date;
}

export const auth = writable<AuthState>({
  user: null,
  accessToken: null,
  shapeTokens: new Map()
});

export async function login(email: string, password: string) {
  const response = await fetch('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });

  if (response.ok) {
    const { user, access_token } = await response.json();
    auth.update(state => ({
      ...state,
      user,
      accessToken: access_token
    }));
    return { success: true };
  }

  return { success: false, error: 'Invalid credentials' };
}

export async function requestShapeToken(
  table: string,
  params: ShapeParams
): Promise<ShapeToken> {
  const { accessToken } = get(auth);

  const response = await fetch(`/api/gatekeeper/${table}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`
    },
    body: JSON.stringify({ params })
  });

  if (!response.ok) {
    throw new Error('Failed to obtain shape token');
  }

  const { token, shape, expires_in } = await response.json();
  const expiresAt = new Date(Date.now() + expires_in * 1000);

  const shapeToken = { token, shape, expiresAt };

  // Cache token
  auth.update(state => {
    const newTokens = new Map(state.shapeTokens);
    newTokens.set(`${table}:${JSON.stringify(params)}`, shapeToken);
    return { ...state, shapeTokens: newTokens };
  });

  return shapeToken;
}
```

#### 2. Authenticated ElectricSQL Client

```typescript
// src/lib/electric/client.ts
import { ShapeStream } from '@electric-sql/client';
import { requestShapeToken } from '$lib/stores/auth';

export async function createAuthenticatedShape(
  table: string,
  params: ShapeParams
) {
  // Get shape-scoped token from gatekeeper
  const { token, shape } = await requestShapeToken(table, params);

  // Create shape stream with token
  const stream = new ShapeStream({
    url: `${ELECTRIC_URL}/v1/shape`,
    params: {
      table: shape.table,
      where: shape.where,
      // Include token in request
      token: token
    }
  });

  return stream;
}
```

#### 3. Token Refresh Logic

```typescript
// src/lib/electric/sync.ts
export class AuthenticatedSyncManager {
  private tokenRefreshTimers = new Map<string, NodeJS.Timeout>();

  async syncShape(table: string, params: ShapeParams) {
    const shapeToken = await requestShapeToken(table, params);

    // Setup auto-refresh before expiry
    this.scheduleTokenRefresh(table, params, shapeToken);

    // Create and return shape stream
    return createAuthenticatedShape(table, params);
  }

  private scheduleTokenRefresh(
    table: string,
    params: ShapeParams,
    token: ShapeToken
  ) {
    const key = `${table}:${JSON.stringify(params)}`;
    const refreshTime = token.expiresAt.getTime() - Date.now() - 60000; // 1 min before expiry

    const timer = setTimeout(async () => {
      try {
        await requestShapeToken(table, params);
        // Token cached in auth store, shapes will use new token
      } catch (err) {
        console.error('Failed to refresh shape token:', err);
      }
    }, refreshTime);

    this.tokenRefreshTimers.set(key, timer);
  }
}
```

### Authorizing Proxy Implementation

#### Option 1: Caddy Reverse Proxy

```caddyfile
# Caddyfile
{$DOMAIN}:443 {
  @electric path /proxy/v1/shape*

  handle @electric {
    # Validate JWT
    jwt {
      primary true
      path /proxy/v1/shape
      allow * {
        validate iss {$JWT_ISSUER}
        validate exp
      }
    }

    # Extract shape claim and validate against query params
    reverse_proxy {$ELECTRIC_URL} {
      header_up X-User-Id {jwt.sub}
      # Proxy validates shape claim matches request
    }
  }

  reverse_proxy {$BACKEND_URL}
}
```

#### Option 2: Phoenix Plug

```elixir
# lib/sertantai_controls_web/plugs/electric_proxy.ex
defmodule SertantaiControlsWeb.Plugs.ElectricProxy do
  import Plug.Conn

  def init(opts), do: opts

  def call(%{request_path: "/proxy/v1/shape"} = conn, _opts) do
    with {:ok, token} <- extract_token(conn),
         {:ok, claims} <- Guardian.decode_and_verify(token),
         :ok <- verify_shape_matches(conn.params, claims["shape"]) do

      # Forward to Electric
      proxy_to_electric(conn, token)
    else
      {:error, reason} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: reason})
        |> halt()
    end
  end

  defp verify_shape_matches(params, shape_claim) do
    if params["table"] == shape_claim["table"] and
       params["where"] == shape_claim["where"] do
      :ok
    else
      {:error, "Shape parameters don't match token"}
    end
  end

  defp proxy_to_electric(conn, token) do
    # Proxy request to Electric with validated token
    # Implementation depends on HTTP client library
  end
end
```

### Security Considerations

#### Token Security
- **Expiration**: Tokens expire after 1 hour (configurable)
- **Scope Limiting**: Each token authorizes exactly one shape definition
- **Rotation**: Automatic token refresh before expiry
- **Revocation**: Backend can invalidate tokens via blacklist if needed

#### Authorization Logic
- **Principle of Least Privilege**: Users only get tokens for data they need
- **Multi-tenancy**: Organization/tenant IDs embedded in shape definitions
- **Row-Level Security**: WHERE clauses in shapes enforce data isolation
- **Audit Trail**: Token generation logged for security monitoring

#### Attack Vectors & Mitigations
- **Token Theft**: Short expiration limits window of compromise
- **Shape Manipulation**: Proxy validates shape matches token claim
- **Replay Attacks**: Tokens include timestamps and can be one-time use
- **Privilege Escalation**: Gatekeeper enforces business rules before token issuance

### Testing Authentication

#### Unit Tests
- Gatekeeper authorization logic
- Token generation and validation
- Shape claim verification
- Permission checking

#### Integration Tests
- Full auth flow (login → token → shape access)
- Token expiry and refresh
- Unauthorized access attempts
- Multi-tenant isolation

#### E2E Tests
- User login → data sync → logout
- Concurrent users with different permissions
- Token expiration during active session
- Offline → online with expired token

## ElectricSQL Integration

### Setup Requirements

1. **PostgreSQL Configuration**
   - Enable logical replication
   - Configure wal_level = logical
   - Install Electric extensions

2. **Electric Sync Service**
   - Configure database connection
   - Set up replication slots
   - Configure sync rules

3. **Frontend Client**
   - Initialize Electric client
   - Define shape subscriptions
   - Handle sync conflicts

4. **Backend Integration**
   - Define DDLX permissions
   - Set up triggers for sync
   - Handle Electric events

### Sync Strategy

- **Offline-first**: Client can operate without connection
- **Optimistic updates**: Immediate UI feedback
- **Conflict resolution**: Last-write-wins with timestamps
- **Selective sync**: Users only sync relevant data

## Development Workflow

### Prerequisites

1. Docker & Docker Compose
2. Elixir 1.16+ and Erlang/OTP 26+
3. Node.js 20+ and npm
4. Make

**Note**: All services run locally. The `~/Desktop/infrastructure` project is for **production only**.

### Getting Started

```bash
# Step 1: Clone repository
git clone <repo-url>
cd sertantai-controls

# Step 2: Install dependencies
make setup      # Install dependencies for frontend and backend

# Step 3: Start all services
make dev        # Starts PostgreSQL, Electric, proxy, backend, and frontend

# Step 4: Run migrations
make migrate

# Step 5: Seed database (optional)
make seed

# Access the application
# PostgreSQL: localhost:5432
# Frontend: http://localhost:5173
# Backend API: http://localhost:4000
# Auth Proxy: http://localhost:3000
# Electric: http://localhost:5133
```

### Makefile Commands

```makefile
setup: Install dependencies and setup environment
dev: Start development environment
stop: Stop all services
clean: Clean build artifacts and dependencies
migrate: Run database migrations
rollback: Rollback last migration
seed: Seed database with test data
test: Run all tests
test-frontend: Run frontend tests
test-backend: Run backend tests
lint: Run all linters
format: Format all code
build: Build production artifacts
```

### Hot Reload Setup

- **Frontend**: Vite HMR with WebSocket connection
- **Backend**: Phoenix code reloader
- **Database**: Auto-migrations in dev mode

## Security Considerations

### Left-Shift Security Practices

1. **Pre-commit Hooks** (Husky/Lefthook):
   - Format check
   - Lint check
   - Secret scanning (git-secrets)
   - Dependency audit

2. **Dependency Management**:
   - Automated dependency updates (Dependabot/Renovate)
   - Security vulnerability scanning
   - License compliance checking

3. **Code Security**:
   - SAST tools (Semgrep, Sobelow)
   - SQL injection prevention (Ecto parameterized queries)
   - XSS prevention (proper escaping)
   - CSRF protection (Phoenix built-in)

4. **Authentication & Authorization**:
   - JWT token-based auth
   - Role-based access control (RBAC)
   - API rate limiting
   - Password strength requirements

5. **Infrastructure Security**:
   - Environment variable management
   - Secrets encryption at rest
   - TLS/SSL everywhere
   - Database connection encryption

## Environment Variables

### Frontend (.env.example)

```bash
# API Configuration
PUBLIC_API_URL=http://localhost:4000
PUBLIC_ELECTRIC_URL=http://localhost:5133  # ElectricSQL v1.0 HTTP Shape API

# Environment
PUBLIC_ENV=development

# Authentication
PUBLIC_TOKEN_REFRESH_BUFFER_MS=60000  # Refresh 1 min before expiry

# Feature Flags
PUBLIC_ENABLE_DEBUG=true
```

### Backend (.env.example)

```bash
# Database (connects to infrastructure project's postgres)
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/sertantai_controls_dev
ELECTRIC_DATABASE_URL=postgresql://postgres:postgres@postgres:5432/sertantai_controls_electric

# Phoenix
SECRET_KEY_BASE=<generate-with-mix-phx.gen.secret>
PHX_HOST=localhost
PORT=4000

# CORS Configuration
FRONTEND_URL=http://localhost:5173  # Dev: Vite server | Prod: CDN URL (e.g., https://app.example.com)

# Electric v1.0
ELECTRIC_URL=http://localhost:5133
ELECTRIC_WRITE_TO_PG_MODE=direct_writes

# Authentication (for sertantai-auth JWT validation)
SHARED_JWT_SECRET=<same-secret-as-sertantai-auth>
GUARDIAN_ISSUER=sertantai_auth

# Environment
MIX_ENV=dev

# Production-only variables (set in deployment environment):
# FRONTEND_URL=https://app.example.com
# DATABASE_URL=<managed-postgres-connection-string>
# SECRET_KEY_BASE=<production-secret>
```

## Database Migrations Strategy

### Migration Workflow

1. **Create Migration**: Ecto migration with Electric DDLX grants
2. **Test Migration**: Run in dev/test environments
3. **Review**: Check for breaking changes, indexes, constraints
4. **Deploy**: Zero-downtime migration strategy
5. **Rollback Plan**: Always have rollback scripts ready

### ElectricSQL Considerations

- Use Electric-compatible DDL
- Define proper sync permissions in DDLX
- Test sync behavior with migration changes
- Handle schema versioning for offline clients

## Documentation Requirements

### docs/architecture.md
- System architecture diagram
- Data flow diagrams
- ElectricSQL sync architecture
- Component relationships

### docs/api.md
- REST API endpoints
- GraphQL schema (if used)
- Authentication flow
- Rate limiting rules

### docs/deployment.md
- Deployment procedures
- Environment configuration
- Rollback procedures
- Database backup/restore

### docs/development.md
- Setup instructions
- Development workflow
- Coding standards
- Contribution guidelines

## Next Steps (Implementation Order)

1. **Foundation** ✅ COMPLETE:
   - [x] Initialize Git repository
   - [x] Create directory structure
   - [x] Setup .gitignore files
   - [x] Create README.md
   - [x] Configure Git hooks (pre-commit, pre-push)
   - [x] Setup GitHub Actions CI/CD
   - [x] Install quality tools (Credo, Dialyzer, ESLint, Prettier, Vitest)
   - [x] First commit and push to GitHub

2. **Backend Bootstrap** (Partially Complete):
   - [x] Initialize Phoenix project with Ash Framework 3.0
   - [x] Setup Ash.Domain (SertantaiControls.Api)
   - [x] Create database schema and migrations (8 resources)
   - [x] Implement comprehensive seed data
   - [x] Define read-only Auth resources (User, Organization)
   - [x] Define Safety domain resources (Control, ControlProvider, ControlInteraction, etc.)
   - [x] Configure Ecto.Repo with multi-tenancy support
   - [x] Setup ExUnit testing framework
   - [x] Configure database connection
   - [x] Add Plug.Cors dependency and configure CORS
   - [ ] Setup JWT validation for sertantai-auth tokens (blocked: waiting for sertantai-auth updates)
   - [x] Setup ElectricSQL v1.0 integration (Docker Compose configured, not running yet)
   - [x] Create health check endpoint (basic + detailed with database checks)

3. **Frontend Bootstrap** (In Progress):
   - [x] Initialize SvelteKit project (minimal template)
   - [x] Configure TypeScript
   - [x] Setup ESLint with TypeScript and Svelte plugins
   - [x] Setup Prettier with Svelte plugin
   - [x] Setup Vitest testing framework
   - [x] Setup TailwindCSS v4 (with @tailwindcss/forms, @tailwindcss/typography)
   - [ ] Create auth store with token management
   - [ ] Implement login redirect to sertantai-auth
   - [ ] Install and configure TanStack DB
   - [ ] Define initial collections structure
   - [ ] Configure ElectricSQL v1.0 client
   - [ ] Integrate TanStack DB with ElectricSQL sync
   - [ ] Implement token refresh mechanism

4. **DevOps Setup** (Mostly Complete):
   - [x] Setup Git hooks (pre-commit with 7 checks, pre-push with 5 checks)
   - [x] Configure GitHub Actions CI/CD (3 jobs: backend, frontend, integration)
   - [x] Install and configure Credo, Dialyzer, mix_audit
   - [x] Install and configure ESLint, Prettier, Vitest
   - [x] Make hooks executable and test full commit/push cycle
   - [x] Create Docker configurations (PostgreSQL, Electric v1.0, Backend, Frontend)
   - [x] Setup docker-compose.dev.yml (local development network)
   - [ ] Create Makefile with development commands
   - [ ] Setup frontend deployment to Cloudflare Pages/Netlify
   - [x] Configure CORS environment variables per environment
   - [ ] Prepare production deployment configs for infrastructure project

5. **Integration**:
   - [ ] Test full authentication flow (login → shape token → access)
   - [ ] Verify gatekeeper authorization logic for multi-tenancy
   - [ ] Test token expiry and refresh mechanisms
   - [ ] Validate proxy JWT verification
   - [ ] Verify TanStack DB collections persist to IndexedDB
   - [ ] Test TanStack DB live queries and reactivity
   - [ ] Connect authenticated ElectricSQL shapes to TanStack DB collections
   - [ ] Verify bidirectional sync with authorization (local → backend → other clients)
   - [ ] Test optimistic mutations and rollback scenarios
   - [ ] Validate conflict resolution
   - [ ] Test unauthorized access attempts (should fail)
   - [ ] Create comprehensive integration test suite

6. **Domain Modeling** (After framework is ready):
   - [ ] Define Ash resources and domains
   - [ ] Create database migrations
   - [ ] Implement business logic
   - [ ] Build UI components

## Success Criteria

**Phase 1: CI/CD & Quality** ✅ COMPLETE
- [x] Git repository initialized and connected to GitHub
- [x] Pre-commit hooks running (formatting, compilation, Credo, Ash codegen, ESLint, TypeScript)
- [x] Pre-push hooks running (Dialyzer, security audit, tests)
- [x] GitHub Actions CI/CD pipeline functional
- [x] Backend quality tools configured (Credo, Dialyzer, mix_audit)
- [x] Frontend quality tools configured (ESLint, Prettier, Vitest)
- [x] First successful commit and push to remote

**Phase 2: Database & Backend** (In Progress)
- [x] Database schema defined (8 resources)
- [x] Migrations created and tested
- [x] Seed data comprehensive
- [x] Ash resources defined with calculations and actions
- [ ] All services start successfully with `make dev`
- [ ] Database connection configured
- [ ] ElectricSQL v1.0 integration working
- [ ] Health check endpoint functional
- [ ] Backend tests passing

**Phase 3: Frontend & Sync** (Not Started)
- [ ] TanStack DB collections defined and persist correctly
- [ ] ElectricSQL client configured with HTTP Shape API
- [ ] Live queries update reactively with sub-ms performance
- [ ] Optimistic mutations provide instant UI feedback
- [ ] Bidirectional sync functional

**Phase 4: Authentication** (Not Started)
- [ ] JWT validation from sertantai-auth working
- [ ] Multi-tenant data isolation enforced
- [ ] Unauthorized access attempts correctly rejected
- [ ] User/Organization data syncing from sertantai-auth

**Phase 5: Polish & Production** (Not Started)
- [ ] Hot reload works for both frontend and backend
- [ ] Documentation complete and accurate
- [ ] Security scans pass without critical issues
- [ ] Code coverage meets 80% threshold
- [ ] Production deployment configured

---

**Last Updated**: 2025-11-14 (after first commit)
**Version**: 6.0
**Changes**:
- v1.0: Initial blueprint
- v2.0: Added TanStack DB clarification and Gatekeeper authentication
- v3.0: Updated for infrastructure project integration, added CORS configuration, separated frontend deployment to CDN
- v4.0: Clarified infrastructure is production-only; development uses local PostgreSQL in Docker Compose
- v5.0: MAJOR ARCHITECTURAL CHANGE - Centralized authentication via sertantai-auth app
  - Authentication now handled by separate `sertantai-auth` service
  - This app validates JWTs and syncs user/org data via ElectricSQL (read-only)
  - Shared database strategy across all sertantai-* apps
- **v6.0: Updated to reflect actual implementation after first commit**
  - ElectricSQL v1.0 HTTP Shape API (removed proxy architecture from v0.12.1)
  - Ash Framework 3.0 with Ash.Domain (not Ash.Api)
  - Comprehensive CI/CD with Git hooks (pre-commit: 7 checks, pre-push: 5 checks)
  - GitHub Actions with 3 jobs (backend-checks, frontend-checks, integration-tests)
  - Quality tools configured: Credo, Dialyzer, mix_audit, ESLint, Prettier, Vitest
  - Backend: 8 resources defined, migrated, and seeded
  - Frontend: SvelteKit minimal template with TypeScript and quality tools
  - Updated directory structure to match actual Ash 3.0 patterns
  - Updated Docker Compose to reflect ElectricSQL v1.0 (no proxy service)
  - Updated success criteria with completion checkmarks

**Status**: Phase 1 Complete - CI/CD & Quality Tools (15% complete). Backend schema and resources defined. Ready for local development environment setup.
