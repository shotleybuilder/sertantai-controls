# Architecture

## Overview

Sertantai Controls is built with a modern, offline-first architecture using:

- **Frontend**: SvelteKit + TanStack DB + ElectricSQL
- **Backend**: Phoenix + Ash Framework + ElectricSQL
- **Database**: PostgreSQL with logical replication

## System Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Svelte UI Layer                   │
│            (Components, Routes, Stores)             │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│                  TanStack DB                        │
│  (Local persistence, sub-ms queries)                │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│              ElectricSQL Client                     │
│  (Shape subscriptions with JWT tokens)              │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│         Authorizing Proxy (JWT Validation)          │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│           ElectricSQL Sync Service                  │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│    PostgreSQL + Phoenix/Ash Backend                 │
│  (Source of truth, gatekeeper auth)                 │
└─────────────────────────────────────────────────────┘
```

## Data Flow

See [sertantai-controls-blueprint.md](../sertantai-controls-blueprint.md) for detailed data flow patterns.

## Key Components

### TanStack DB
- Local persistence via IndexedDB
- Differential dataflow for sub-millisecond queries
- Optimistic mutations with automatic rollback

### ElectricSQL
- Real-time bidirectional sync
- Shape-based subscriptions
- CRDT conflict resolution

### Gatekeeper Authentication
- Shape-scoped JWT tokens
- Row-level security enforcement
- Multi-tenant data isolation

## Component Relationships

TODO: Add detailed component diagrams
