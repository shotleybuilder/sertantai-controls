# Sertantai-Controls Project Blueprint

## Project Overview

A full-stack application consisting of:
- **Frontend**: Svelte + TanStack DB + ElectricSQL client
- **Backend**: Elixir + Phoenix + Ash Framework + ElectricSQL

**Data Architecture**: TanStack DB provides local persistence and lightning-fast UI through differential dataflow, enabling sub-millisecond queries across normalized collections. ElectricSQL handles real-time sync between the local TanStack DB store and the PostgreSQL backend, creating a truly offline-first, reactive application.

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
│   ├── mix.exs
│   ├── mix.lock
│   ├── .formatter.exs
│   ├── .credo.exs
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
│   │   │   ├── application.ex
│   │   │   ├── repo.ex
│   │   │   ├── resources/
│   │   │   ├── domains/
│   │   │   └── electric/
│   │   │       └── sync.ex
│   │   └── sertantai_controls_web/
│   │       ├── endpoint.ex
│   │       ├── router.ex
│   │       ├── controllers/
│   │       │   ├── auth_controller.ex
│   │       │   └── gatekeeper_controller.ex
│   │       ├── plugs/
│   │       │   ├── auth_plug.ex
│   │       │   └── electric_proxy.ex
│   │       ├── live/
│   │       └── graphql/
│   ├── priv/
│   │   ├── repo/
│   │   │   ├── migrations/
│   │   │   └── seeds.exs
│   │   └── static/
│   └── test/
│       ├── sertantai_controls/
│       ├── sertantai_controls_web/
│       ├── support/
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

## CI/CD Pipeline (GitHub Actions)

### Frontend CI Pipeline (.github/workflows/frontend-ci.yml)

**Stages**:
1. **Lint**: ESLint, Prettier, Svelte-check
2. **Type Check**: TypeScript validation
3. **Test**: Vitest unit tests with coverage
4. **Build**: Vite production build
5. **E2E Tests**: Playwright tests (on PR)
6. **Security Scan**: npm audit, Snyk
7. **Deploy Preview**: Deploy to staging environment (on PR)

**Triggers**: Push to feature/*, develop, main; Pull requests

### Backend CI Pipeline (.github/workflows/backend-ci.yml)

**Stages**:
1. **Compile**: Mix compile with warnings as errors
2. **Format Check**: mix format --check-formatted
3. **Lint**: Credo static analysis
4. **Test**: ExUnit tests with coverage (min 80%)
5. **Dialyzer**: Type checking
6. **Security Scan**: mix deps.audit, Sobelow
7. **Build Docker Image**: Build and tag image

**Triggers**: Push to feature/*, develop, main; Pull requests

### Integration Tests Pipeline (.github/workflows/integration-tests.yml)

**Stages**:
1. **Spin Up Services**: Docker Compose (Postgres, Electric, Backend, Frontend)
2. **Wait for Health Checks**
3. **Run Integration Tests**: API + ElectricSQL sync tests
4. **Tear Down Services**

**Triggers**: Pull requests to develop/main

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

#### Test Commands
```bash
npm run test           # Run unit tests
npm run test:watch     # Watch mode
npm run test:coverage  # Generate coverage report
npm run test:e2e       # Run E2E tests
npm run test:e2e:ui    # E2E with UI
```

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

#### Infrastructure Dependencies

This project deploys into the **~/Desktop/infrastructure** environment which provides:
- **PostgreSQL 15**: Unified database service with ElectricSQL extensions
- **Common Docker networking**: Shared network configuration
- **Base docker-compose configs**: Reusable service definitions

#### Project Docker Compose Services

**docker-compose.dev.yml** (project-specific services only):
- **electric**: ElectricSQL sync service (connects to infrastructure postgres)
- **proxy**: Authorizing proxy for Electric (Caddy or custom)
- **backend**: Phoenix application (includes gatekeeper)
- **frontend**: Vite dev server with HMR

#### Service Configuration

```yaml
# PostgreSQL (provided by infrastructure project)
Host: postgres (from infrastructure network)
Port: 5432
Database: sertantai_controls_dev
User: postgres
Electric logical replication enabled

# ElectricSQL
Port: 5133 (HTTP), 5433 (Postgres proxy)
Connected to infrastructure postgres via docker network
Not directly accessible (behind auth proxy)

# Authorizing Proxy
Port: 3000
Validates JWT tokens
Forwards authorized requests to Electric :5133
Validates shape claims match requests

# Backend (Phoenix)
Port: 4000
Environment: development
Hot reload enabled
CORS enabled via Plug.Cors (allows frontend :5173)
Provides gatekeeper endpoints at /api/gatekeeper/:table
Connects to infrastructure postgres

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
  # Connect to infrastructure project's network
  infrastructure:
    external: true
    name: infrastructure_default

services:
  # ElectricSQL sync service
  electric:
    image: electricsql/electric:latest
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/sertantai_controls_dev
      LOGICAL_PUBLISHER_HOST: postgres
      LOGICAL_PUBLISHER_PORT: 5432
    ports:
      - "5133:5133"
      - "5433:5433"
    networks:
      - infrastructure
    depends_on:
      - postgres  # From infrastructure project

  # Authorizing proxy for Electric
  proxy:
    build: ./proxy
    environment:
      ELECTRIC_URL: http://electric:5133
      JWT_SECRET: ${GUARDIAN_SECRET_KEY}
      JWT_ISSUER: sertantai_controls
    ports:
      - "3000:3000"
    networks:
      - infrastructure
    depends_on:
      - electric

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
      - infrastructure
    depends_on:
      - postgres  # From infrastructure project
      - electric
    command: mix phx.server

  # Vite dev server
  frontend:
    build: ./frontend
    environment:
      PUBLIC_API_URL: http://localhost:4000
      PUBLIC_ELECTRIC_PROXY_URL: http://localhost:3000
    ports:
      - "5173:5173"
    volumes:
      - ./frontend:/app
      - frontend_node_modules:/app/node_modules
    networks:
      - infrastructure
    command: npm run dev

volumes:
  backend_build:
  backend_deps:
  frontend_node_modules:
```

### Production Environment

#### Infrastructure Requirements

**Backend/Services Hosting**:
- **Option A**: Fly.io (Elixir-optimized, near-user deployments)
- **Option B**: AWS ECS (Elastic Container Service)
- **Option C**: DigitalOcean App Platform

**Frontend Hosting** (Static Assets - Separate from Backend):
- **Option A**: Cloudflare Pages (Recommended - Free, Open Source CLI)
  - Free tier: Unlimited sites, bandwidth, requests
  - Global CDN with 300+ edge locations
  - Automatic SSL/TLS
  - Git integration for auto-deployment
  - Deploy with: `wrangler pages deploy`

- **Option B**: Netlify (Free tier available)
  - 100GB bandwidth/month free
  - Global CDN
  - Automatic HTTPS
  - Git-based deployment
  - Open source CLI: `netlify deploy`

- **Option C**: Vercel (Free for personal/hobby projects)
  - Global edge network
  - Automatic SSL
  - Git integration
  - Open source CLI: `vercel deploy`

- **Option D**: Self-hosted with Caddy
  - Open source web server
  - Automatic HTTPS
  - Host on any VPS (DigitalOcean, Hetzner, etc.)
  - Full control, low cost

#### Services

1. **PostgreSQL Database**
   - Managed PostgreSQL with replication
   - Automated backups (daily, 7-day retention)
   - Connection pooling (PgBouncer)

2. **ElectricSQL Service**
   - Deployed as separate service (not public-facing)
   - Horizontal scaling capability
   - Websocket load balancing

3. **Authorizing Proxy**
   - Edge deployment (Cloudflare Workers, Fly.io edge, or Vercel Edge)
   - JWT validation with shape claim verification
   - Low-latency token checking
   - Routes to nearest Electric instance
   - Fallback to Phoenix proxy if needed

4. **Phoenix Backend**
   - Multiple instances (min 2 for redundancy)
   - Auto-scaling based on CPU/memory
   - Hosts gatekeeper endpoints
   - Health check endpoint: /health
   - CORS configured for production frontend domain
   - Can also serve as proxy fallback
   - Does NOT serve frontend static assets

5. **Frontend (Svelte/SvelteKit)**
   - Built static assets deployed to CDN
   - Separate deployment pipeline from backend
   - Environment variables configured for production API/proxy URLs
   - Global edge caching
   - Automatic SSL/TLS certificates
   - Sub-100ms response times globally

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

**Code Quality**:
- ESLint
- Prettier
- TypeScript strict mode

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

**Code Quality**:
- Credo
- Dialyzer
- ExCoveralls

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
│         Authorizing Proxy (JWT Validation)          │
│    Validates shape-scoped tokens, forwards to       │
│            Electric if authorized                   │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│           ElectricSQL Sync Service                  │
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

## Authentication: Gatekeeper Pattern

### Overview

The gatekeeper pattern provides shape-scoped authorization for ElectricSQL sync. Rather than authorizing every request, clients obtain a JWT token that encodes exactly which data shapes they're authorized to access. This moves authorization logic off the "hot path" and enables efficient edge deployment.

### Authentication Flow

```
┌─────────┐                                  ┌──────────────┐
│ Client  │                                  │   Backend    │
│         │                                  │  Gatekeeper  │
└────┬────┘                                  └──────┬───────┘
     │                                               │
     │ 1. Login with credentials                    │
     │ ──────────────────────────────────────────> │
     │                                               │
     │                      2. Validate credentials │
     │                      3. Check permissions    │
     │                      4. Generate JWT with    │
     │                         shape claims         │
     │                                               │
     │ 5. Return JWT + shape definition             │
     │ <────────────────────────────────────────── │
     │                                               │
     │                                        ┌──────────────┐
     │                                        │ Auth Proxy   │
     │                                        └──────┬───────┘
     │                                               │
     │ 6. Request shape with JWT                    │
     │ ──────────────────────────────────────────> │
     │                                               │
     │                      7. Validate JWT         │
     │                      8. Verify shape matches │
     │                         token claims         │
     │                                               │
     │                                        ┌──────────────┐
     │                                        │  ElectricSQL │
     │                                        └──────┬───────┘
     │                                               │
     │                      9. Forward if authorized│
     │                      ─────────────────────> │
     │                                               │
     │ 10. Stream shape data                        │
     │ <──────────────────────────────────────────────────── │
     │                                               │
```

### Backend Implementation (Phoenix/Ash)

#### 1. Gatekeeper Endpoints

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

1. **Infrastructure Project**: Ensure `~/Desktop/infrastructure` is set up and running
   - Provides PostgreSQL with ElectricSQL extensions
   - Provides shared Docker network
   - Must be started before this project

### Getting Started

```bash
# Step 1: Start infrastructure services (in separate terminal)
cd ~/Desktop/infrastructure
docker-compose up -d  # Starts postgres and shared services

# Step 2: Clone and setup this project
git clone <repo-url>
cd sertantai-controls

# Step 3: Install dependencies
make setup      # Install dependencies for frontend and backend

# Step 4: Start project services
make dev        # Start Electric, proxy, backend, and frontend
                # Connects to infrastructure postgres automatically

# Step 5: Run migrations
make migrate

# Step 6: Seed database
make seed

# Access the application
# Frontend: http://localhost:5173
# Backend API: http://localhost:4000
# Auth Proxy: http://localhost:3000
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
PUBLIC_ELECTRIC_PROXY_URL=http://localhost:3000  # Authorizing proxy, not direct Electric

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

# Electric
ELECTRIC_URL=http://localhost:5133
ELECTRIC_PROXY_URL=http://localhost:3000  # Public-facing proxy URL
ELECTRIC_WRITE_TO_PG_MODE=direct_writes

# Authentication
GUARDIAN_SECRET_KEY=<generate-with-mix-guardian.gen.secret>
GUARDIAN_ISSUER=sertantai_controls
TOKEN_SIGNING_SECRET=<generate-secure-secret>

# Shape Tokens
SHAPE_TOKEN_TTL=3600  # 1 hour in seconds
SHAPE_TOKEN_TYPE=Bearer

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

1. **Foundation**:
   - [ ] Initialize Git repository
   - [ ] Create directory structure
   - [ ] Setup .gitignore files
   - [ ] Create README.md with badges

2. **Backend Bootstrap**:
   - [ ] Initialize Phoenix project with Ash
   - [ ] Configure database connection to infrastructure postgres
   - [ ] Add Plug.Cors dependency and configure CORS
   - [ ] Setup AshAuthentication with password strategy
   - [ ] Implement User resource with organization relationship
   - [ ] Create gatekeeper controller for shape token generation
   - [ ] Implement authorizing proxy (Phoenix Plug or Caddy)
   - [ ] Setup Guardian for JWT management
   - [ ] Setup ElectricSQL (connecting to infrastructure postgres)
   - [ ] Create health check endpoint
   - [ ] Setup testing framework

3. **Frontend Bootstrap**:
   - [ ] Initialize SvelteKit project
   - [ ] Configure TypeScript
   - [ ] Setup TailwindCSS
   - [ ] Create auth store with token management
   - [ ] Implement login/logout functionality
   - [ ] Build shape token request logic
   - [ ] Install and configure TanStack DB
   - [ ] Define initial collections structure
   - [ ] Configure ElectricSQL client with auth
   - [ ] Integrate TanStack DB with authenticated ElectricSQL sync
   - [ ] Implement token refresh mechanism
   - [ ] Setup testing framework

4. **DevOps Setup**:
   - [ ] Verify infrastructure project setup (~/Desktop/infrastructure)
   - [ ] Create Docker configurations (Electric, Proxy, Backend, Frontend)
   - [ ] Setup docker-compose.dev.yml (connects to infrastructure network)
   - [ ] Create Makefile with infrastructure dependency checks
   - [ ] Configure CI/CD pipelines (separate backend + frontend deployments)
   - [ ] Setup frontend deployment to Cloudflare Pages/Netlify
   - [ ] Configure CORS environment variables per environment
   - [ ] Setup pre-commit hooks

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

- [ ] All services start successfully with `make dev`
- [ ] Gatekeeper authentication flow works end-to-end
- [ ] Shape-scoped JWT tokens are properly validated
- [ ] Unauthorized access attempts are correctly rejected
- [ ] Token refresh mechanism works automatically
- [ ] TanStack DB collections persist and sync correctly
- [ ] Live queries update reactively with sub-ms performance
- [ ] Optimistic mutations provide instant UI feedback
- [ ] ElectricSQL bidirectional sync is functional
- [ ] Multi-tenant data isolation is enforced
- [ ] Tests run and pass in CI/CD pipeline
- [ ] Hot reload works for both frontend and backend
- [ ] Documentation is complete and accurate
- [ ] Security scans pass without critical issues
- [ ] Code coverage meets 80% threshold

---

**Last Updated**: 2025-11-13
**Version**: 3.0
**Changes**:
- v1.0: Initial blueprint
- v2.0: Added TanStack DB clarification and Gatekeeper authentication
- v3.0: Updated for infrastructure project integration, added CORS configuration, separated frontend deployment to CDN

**Status**: Blueprint - Not Yet Implemented
