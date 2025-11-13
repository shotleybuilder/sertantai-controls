# Development Guide

## Getting Started

See the main [README.md](../README.md) for quick start instructions.

## Development Environment

### Prerequisites

1. Docker & Docker Compose
2. Elixir 1.16+ and Erlang/OTP 26+
3. Node.js 20+ and npm
4. Make

**Note**: All services run locally in Docker. The `~/Desktop/infrastructure` project is for production deployment only, not required for development.

### Setup

```bash
# Setup project
cd ~/Desktop/sertantai-controls
make setup

# Start all services (PostgreSQL, Electric, Proxy, Backend, Frontend)
make dev
```

### Local Services

Running `make dev` starts:
- **PostgreSQL 15**: Local database with logical replication enabled
- **ElectricSQL**: Sync service connected to local PostgreSQL
- **Auth Proxy**: JWT validation proxy
- **Phoenix Backend**: API server with hot reload
- **Vite Frontend**: Development server with HMR

All services communicate on the `sertantai_network` Docker network.

## Coding Standards

### Frontend (TypeScript/Svelte)

- Use TypeScript strict mode
- Follow Airbnb style guide (via ESLint)
- Components in PascalCase
- Files in kebab-case
- Maximum line length: 100 characters

### Backend (Elixir)

- Follow Elixir style guide
- Use Credo for linting
- Maximum line length: 120 characters
- Document public functions with @doc
- Use typespecs for all public functions

## Testing

### Frontend

```bash
# Unit tests
npm run test

# Watch mode
npm run test:watch

# Coverage
npm run test:coverage

# E2E tests
npm run test:e2e
```

### Backend

```bash
# Unit tests
mix test

# Watch mode
mix test.watch

# Coverage
mix test --cover

# Integration tests only
mix test --only integration
```

## Git Workflow

### Branch Naming

- `feature/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation updates
- `test/` - Test additions or fixes

### Commit Messages

Follow conventional commits format:

```
type(scope): subject

body (optional)

footer (optional)
```

Types:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `style` - Formatting
- `refactor` - Code restructuring
- `test` - Tests
- `chore` - Maintenance

Example:
```
feat(auth): implement gatekeeper token generation

Add shape-scoped JWT token generation for ElectricSQL authorization.
Includes multi-tenant filtering and token expiration.

Closes #123
```

## Code Review

- All changes require PR review
- Minimum 1 approval required
- CI must pass
- Coverage must not decrease
- No unresolved comments

## Debugging

### Frontend

Use browser DevTools:
- Sources tab for breakpoints
- Application tab for IndexedDB inspection
- Network tab for API calls

### Backend

```bash
# Start with IEx
iex -S mix phx.server

# Enable debug logging
config :logger, level: :debug
```

## Common Issues

### PostgreSQL Connection Failed

Ensure local PostgreSQL container is running:
```bash
docker-compose -f docker-compose.dev.yml ps postgres
docker-compose -f docker-compose.dev.yml logs postgres
```

Restart if needed:
```bash
docker-compose -f docker-compose.dev.yml restart postgres
```

### Port Already in Use

Check if port is in use:
```bash
lsof -ti:5432  # PostgreSQL
lsof -ti:4000  # Backend
lsof -ti:5173  # Frontend
lsof -ti:3000  # Proxy
```

Kill process or stop all services:
```bash
make stop
```

### Dependencies Out of Sync

```bash
# Frontend
cd frontend && rm -rf node_modules && npm install

# Backend
cd backend && rm -rf deps _build && mix deps.get
```

### Docker Volume Issues

Clean up all volumes and restart:
```bash
make clean
make dev
```

## Additional Resources

- [Architecture](architecture.md)
- [API Documentation](api.md)
- [Deployment Guide](deployment.md)
- [Project Blueprint](../sertantai-controls-blueprint.md)
