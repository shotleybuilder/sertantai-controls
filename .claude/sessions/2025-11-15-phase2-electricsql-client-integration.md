# Phase 2: ElectricSQL Client App Integration

**Date:** 2025-11-15
**Issue:** https://github.com/shotleybuilder/sertantai-controls/issues/1
**Status:** ✅ COMPLETE

## Quick Reference

**Goal:** Enable ElectricSQL client apps to use sertantai-auth JWTs for multi-tenant data sync.

**Detailed Implementation:** See issue #2 for full task breakdown, code examples, and acceptance criteria.

## Prerequisites Check

- ✅ Phase 1 complete (multi-tenancy in sertantai-auth)
- ✅ Client app has ElectricSQL configured (`sertantai-controls`)
- ✅ Client app uses Phoenix/Ash (perfect match!)

## Progress Tracker

### Backend: Shape Authorization Middleware

- [ ] **JWT Verification Plug** - `lib/your_app_web/plugs/verify_auth_token.ex`
  - Extract token from header
  - Verify JWT signature with `SHARED_TOKEN_SECRET`
  - Validate claims and assign to conn

- [ ] **Electric Sync Endpoint** - `lib/your_app_web/controllers/electric_controller.ex`
  - Handle shape requests with org_id filtering
  - Proxy to Electric with tenant filter

- [ ] **Router Configuration**
  - Add `/electric/sync` route
  - Apply JWT verification plug
  - Configure CORS

### Database: Row-Level Security (RLS)

- [ ] **Schema Updates**
  - Add `organization_id` to tenant-scoped tables
  - Add foreign key constraints
  - Create indexes on `organization_id`

- [ ] **RLS Policies**
  - Enable RLS on all tenant-scoped tables
  - Create `tenant_isolation` policies
  - Set `app.current_org_id` from JWT

- [ ] **Database Triggers** (Optional)
  - Auto-set `organization_id` on INSERT
  - Prevent manual `organization_id` changes
  - Audit logging for cross-tenant attempts

### Frontend: ElectricSQL Integration

- [ ] **Electric Client Setup**
  - Install `@electric-sql/client`
  - Configure with auth token
  - Store JWT from login

- [ ] **Shape Subscriptions**
  - Implement shape subscription pattern
  - Use TanStack Query for reactivity
  - Handle subscription errors

- [ ] **Organization Switcher UI**
  - Create org switcher component
  - Implement switch flow (7 steps - see issue)
  - Clear and re-sync on org change

- [ ] **Token Refresh Handling**
  - Detect token expiry
  - Auto-refresh before expiry
  - Update Electric client with new token

### Testing

- [ ] **Backend Tests**
  - JWT verification (valid/invalid/expired)
  - Electric sync authorization
  - RLS policy validation

- [ ] **Frontend Tests**
  - Electric client init
  - Shape subscriptions
  - Org switcher flow

- [ ] **Integration Tests**
  - End-to-end: Login → Sync → Switch → Re-sync
  - Offline mode with org context
  - Concurrent users isolation

### Documentation

- [ ] Create `CLIENT_INTEGRATION.md`
- [ ] Document RLS policy patterns
- [ ] Add Electric controller example
- [ ] Document org switching flow
- [ ] Add troubleshooting guide

## Implementation Summary

### Phase 1: JWT Authentication ✅
- ✅ Added joken dependency (v2.6)
- ✅ Configured SHARED_TOKEN_SECRET in runtime.exs
- ✅ Created JWT verification plug with user/org/role extraction
- ✅ Updated router with `:authenticated` pipeline
- ✅ Shared database configuration (sertantai_auth_dev)
- ✅ Updated User resource with role and confirmed_at attributes

### Phase 2: ElectricSQL Integration ✅
- ✅ Created Electric sync endpoint controller (proxies to Electric with org_id filtering)
- ✅ Added Electric sync route: `GET /api/electric/sync`
- ✅ RLS migration for tenant isolation (all tenant-scoped tables)
- ✅ PostgreSQL function: `set_current_org_id()`
- ✅ Updated JWT plug to set RLS session variable
- ✅ Added multitenancy config to Control resource
- ✅ CORS configured for frontend Electric client
- ✅ Frontend auth store (JWT + user management)
- ✅ Frontend Electric client with authenticated shapes
- ✅ Shape subscriptions with Svelte stores
- ✅ Documentation and usage examples

### Architecture
**Single-Organization Model:**
- User belongs to ONE organization (user.organization_id)
- JWT contains: user_id, org_id, role
- Multi-org access = multiple accounts
- Simpler than multi-org membership model

**Security Layers:**
1. JWT authentication (backend verifies signature)
2. Electric controller org_id filtering
3. PostgreSQL RLS policies (database-level isolation)

## Current Work

**Status:** ✅ Complete - Ready for testing

**Next Session:** Implementation testing and enhancements (see next steps session doc)

## Blockers / Notes

None - Architecture simplified to single-org model matching blueprint

## Target App Info

**Primary Integration:** `/home/jason/Desktop/sertantai-controls`
- Stack: Phoenix + Ash + ElectricSQL + Svelte ✅
- ElectricSQL: Already configured ✅
- First client app on this stack

**Future Integration:** `ehs_enforcement`
- Currently: LiveView
- Planned: Migrate to Ash + ElectricSQL + Svelte stack
- Will use same patterns after migration

## Key Decisions

_To be documented as we make them_

## Quick Wins

_Small achievements to track momentum_

## Session Notes

### Session 1 - 2025-11-15
- Created session tracker
- Identified target app: `sertantai-controls` (Ash + Electric + Svelte)
- Prerequisites verified - ready to start
- Session doc moved from sertantai-auth to sertantai-controls (correct location)
- Status: Ready to begin implementation

---

**Reference:** Full implementation details in [Issue #2](https://github.com/shotleybuilder/sertantai-auth/issues/2)
