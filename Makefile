.PHONY: help setup dev stop clean migrate rollback seed test test-frontend test-backend lint format build check-infrastructure

# Default target
help:
	@echo "Sertantai Controls - Development Commands"
	@echo ""
	@echo "Setup & Development:"
	@echo "  make setup          - Install dependencies for frontend and backend"
	@echo "  make dev            - Start all development services"
	@echo "  make stop           - Stop all services"
	@echo "  make clean          - Clean build artifacts and dependencies"
	@echo ""
	@echo "Database:"
	@echo "  make migrate        - Run database migrations"
	@echo "  make rollback       - Rollback last migration"
	@echo "  make seed           - Seed database with test data"
	@echo ""
	@echo "Testing:"
	@echo "  make test           - Run all tests"
	@echo "  make test-frontend  - Run frontend tests"
	@echo "  make test-backend   - Run backend tests"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint           - Run all linters"
	@echo "  make format         - Format all code"
	@echo ""
	@echo "Production:"
	@echo "  make build          - Build production artifacts"

# Check if infrastructure is running
check-infrastructure:
	@echo "Checking infrastructure services..."
	@docker network inspect infrastructure_default > /dev/null 2>&1 || \
		(echo "ERROR: Infrastructure network not found. Please start ~/Desktop/infrastructure first." && exit 1)
	@docker ps | grep -q postgres || \
		(echo "ERROR: PostgreSQL not running. Please start ~/Desktop/infrastructure first." && exit 1)
	@echo "Infrastructure services are running."

# Install dependencies
setup: check-infrastructure
	@echo "Installing frontend dependencies..."
	cd frontend && npm install
	@echo "Installing backend dependencies..."
	cd backend && mix deps.get
	@echo "Setup complete!"

# Start development environment
dev: check-infrastructure
	@echo "Starting development services..."
	docker-compose -f docker-compose.dev.yml up -d
	@echo ""
	@echo "Services started!"
	@echo "  Frontend:    http://localhost:5173"
	@echo "  Backend API: http://localhost:4000"
	@echo "  Auth Proxy:  http://localhost:3000"
	@echo ""
	@echo "View logs: docker-compose -f docker-compose.dev.yml logs -f"

# Stop all services
stop:
	@echo "Stopping development services..."
	docker-compose -f docker-compose.dev.yml down

# Clean build artifacts and dependencies
clean:
	@echo "Cleaning build artifacts..."
	cd frontend && rm -rf node_modules .svelte-kit build dist
	cd backend && rm -rf _build deps
	docker-compose -f docker-compose.dev.yml down -v
	@echo "Clean complete!"

# Run database migrations
migrate:
	@echo "Running database migrations..."
	cd backend && mix ecto.migrate

# Rollback last migration
rollback:
	@echo "Rolling back last migration..."
	cd backend && mix ecto.rollback

# Seed database
seed:
	@echo "Seeding database..."
	cd backend && mix run priv/repo/seeds.exs

# Run all tests
test: test-backend test-frontend
	@echo "All tests complete!"

# Run frontend tests
test-frontend:
	@echo "Running frontend tests..."
	cd frontend && npm run test

# Run backend tests
test-backend:
	@echo "Running backend tests..."
	cd backend && mix test

# Run linters
lint:
	@echo "Running linters..."
	@echo "Linting frontend..."
	cd frontend && npm run lint
	@echo "Linting backend..."
	cd backend && mix credo

# Format code
format:
	@echo "Formatting code..."
	@echo "Formatting frontend..."
	cd frontend && npm run format
	@echo "Formatting backend..."
	cd backend && mix format

# Build production artifacts
build:
	@echo "Building production artifacts..."
	@echo "Building frontend..."
	cd frontend && npm run build
	@echo "Building backend..."
	cd backend && MIX_ENV=prod mix release
	@echo "Build complete!"
