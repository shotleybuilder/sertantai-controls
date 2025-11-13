# Development Guide

## Getting Started

See the main [README.md](../README.md) for quick start instructions.

## Development Environment

### Prerequisites

1. Infrastructure project running (`~/Desktop/infrastructure`)
2. Docker & Docker Compose
3. Elixir 1.16+ and Erlang/OTP 26+
4. Node.js 20+ and npm
5. Make

### Setup

```bash
# Start infrastructure
cd ~/Desktop/infrastructure
docker-compose up -d

# Setup project
cd ~/Desktop/sertantai-controls
make setup
make dev
```

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

Ensure infrastructure is running:
```bash
cd ~/Desktop/infrastructure
docker-compose ps
```

### Port Already in Use

Check and kill process:
```bash
lsof -ti:4000 | xargs kill -9
```

### Dependencies Out of Sync

```bash
# Frontend
cd frontend && rm -rf node_modules && npm install

# Backend
cd backend && rm -rf deps _build && mix deps.get
```

## Additional Resources

- [Architecture](architecture.md)
- [API Documentation](api.md)
- [Deployment Guide](deployment.md)
- [Project Blueprint](../sertantai-controls-blueprint.md)
