# Phase 3: Testing & Production Enhancements

**Date:** 2025-11-15
**Previous Session:** 2025-11-15-phase2-electricsql-client-integration.md
**Status:** Ready to Start

## Quick Reference

**Goal:** Test the auth integration, run migrations, and implement production-ready enhancements.

**Prerequisites:**
- ✅ Phase 1: JWT Authentication (complete)
- ✅ Phase 2: ElectricSQL Integration (complete)
- ✅ sertantai-auth single-org architecture (complete)

## Priority Tasks

### 1. Database Setup & Migration

- [ ] **Run RLS Migration**
  ```bash
  cd backend
  mix ash.migrate
  ```
  - Enables Row-Level Security on tenant-scoped tables
  - Creates `set_current_org_id()` PostgreSQL function
  - Adds 4 policies per table (SELECT, INSERT, UPDATE, DELETE)

- [ ] **Verify Migration Success**
  ```bash
  mix ash.migrate --show-tables
  ```
  - Confirm RLS enabled on all tables
  - Check policies exist

- [ ] **Seed Test Data** (if needed)
  - Create test organizations
  - Create test users with different roles
  - Create sample controls in different quadrants

### 2. Integration Testing

- [ ] **Backend: JWT Verification**
  - Get JWT token from sertantai-auth (register or login)
  - Test protected endpoint with valid token
  - Test with invalid/expired token
  - Verify `conn.assigns` populated correctly

- [ ] **Backend: Electric Sync Endpoint**
  - Test shape request with JWT: `GET /api/electric/sync?table=controls`
  - Verify org_id filter added to WHERE clause
  - Test with multiple users from different orgs
  - Confirm data isolation

- [ ] **Database: RLS Policies**
  - Connect to PostgreSQL
  - Manually set org_id: `SELECT set_current_org_id('<uuid>');`
  - Query tables, verify only org data visible
  - Test INSERT/UPDATE/DELETE with different org contexts

- [ ] **Frontend: Auth Flow**
  - Login via sertantai-auth
  - Store JWT in auth store
  - Verify token persists in localStorage
  - Test logout

- [ ] **Frontend: Electric Shapes**
  - Create shape subscription
  - Verify data loads
  - Check network tab for Authorization header
  - Test real-time updates (if Electric running)

- [ ] **End-to-End: Multi-Tenant Isolation**
  - User A logs in (Org 1)
  - User A creates controls
  - User B logs in (Org 2)
  - Verify User B cannot see Org 1 controls
  - Verify both backend and database layers enforce isolation

### 3. Production Enhancements

- [ ] **Environment Variables**
  - Create `.env` from `.env.example` (backend)
  - Set `SHARED_TOKEN_SECRET` (must match sertantai-auth)
  - Create `.env.development` (frontend)
  - Set `PUBLIC_BACKEND_URL=http://localhost:4000`

- [ ] **Token Refresh Logic**
  - Detect token expiry (check JWT `exp` claim)
  - Auto-refresh before expiry
  - Update Electric client with new token
  - Handle refresh failures (logout)

- [ ] **Error Handling**
  - Electric client: Retry failed syncs
  - Auth store: Handle invalid tokens gracefully
  - Backend: Better error messages for auth failures
  - Frontend: Display user-friendly error messages

- [ ] **Security Hardening**
  - Consider HttpOnly cookies vs localStorage for tokens
  - Add CSRF protection if using cookies
  - Rate limiting on auth endpoints
  - Token revocation on logout (backend)

- [ ] **Optimistic Mutations** (Optional)
  - Use TanStack DB for local-first writes
  - Sync to backend after mutation
  - Handle conflicts

- [ ] **Logging & Monitoring**
  - Log auth failures (track potential attacks)
  - Monitor Electric sync errors
  - Track RLS policy violations
  - Performance metrics for shape syncs

### 4. Documentation Updates

- [ ] **README.md**
  - Add authentication setup instructions
  - Document environment variables
  - Add "Getting Started" with auth flow
  - Link to Electric integration docs

- [ ] **API Documentation**
  - Document protected endpoints
  - Show JWT token format
  - Example API calls with curl

- [ ] **Development Guide**
  - How to get JWT for testing
  - How to test with multiple orgs
  - Troubleshooting common auth issues

## Testing Checklist

### Unit Tests

- [ ] Backend: JWT verification plug
  - Test valid token → user loaded
  - Test invalid signature → 401
  - Test expired token → 401
  - Test missing Authorization header → 401
  - Test malformed token → 401

- [ ] Backend: Electric controller
  - Test org_id filter injection
  - Test proxy to Electric service
  - Test error handling

- [ ] Frontend: Auth store
  - Test login/logout
  - Test token persistence
  - Test derived stores

- [ ] Frontend: Electric client
  - Test shape creation with auth
  - Test Authorization header injection
  - Test error handling (401)

### Integration Tests

- [ ] **Auth Flow**
  1. Register user via sertantai-auth
  2. Receive JWT token
  3. Store in auth store
  4. Access protected backend endpoint
  5. Verify user context loaded

- [ ] **Electric Sync Flow**
  1. Login and get JWT
  2. Create shape subscription
  3. Verify data synced
  4. Create new control (if mutations implemented)
  5. Verify real-time sync

- [ ] **Multi-Tenant Isolation**
  1. Create User A (Org 1)
  2. Create User B (Org 2)
  3. User A creates controls
  4. User B attempts access → should fail/empty
  5. Verify in database with RLS
  6. Verify via API
  7. Verify via Electric shapes

### Manual Testing Scenarios

- [ ] **Scenario 1: New User Registration**
  - Register via sertantai-auth
  - Verify default org created
  - Login to sertantai-controls
  - Verify shapes load (empty initially)

- [ ] **Scenario 2: Token Expiry**
  - Login with short-lived token
  - Wait for expiry
  - Attempt shape sync → should fail
  - Implement refresh or re-login

- [ ] **Scenario 3: Concurrent Users**
  - Open two browser sessions
  - Login as User A (Org 1)
  - Login as User B (Org 2)
  - Create controls in both
  - Verify isolation in real-time

- [ ] **Scenario 4: Offline Mode** (Future)
  - Login and sync
  - Go offline
  - Access cached data
  - Create mutations offline
  - Come back online → sync

## Performance Considerations

- [ ] **Electric Shape Optimization**
  - Use `columns` parameter to fetch only needed fields
  - Add WHERE clauses to reduce data volume
  - Monitor network payload sizes

- [ ] **Database Indexing**
  - Ensure `organization_id` indexed on all tables
  - Composite indexes for common queries
  - Monitor slow queries with RLS

- [ ] **Frontend Caching**
  - Cache shape data in TanStack DB
  - Avoid redundant shape subscriptions
  - Implement stale-while-revalidate pattern

- [ ] **Connection Pooling**
  - Review database pool_size settings
  - Monitor connection usage
  - Configure for production load

## Monitoring & Observability

- [ ] **Metrics to Track**
  - Auth failures per minute
  - Token refresh rate
  - Electric sync latency
  - RLS policy execution time
  - Shape subscription count

- [ ] **Logging Strategy**
  - Auth events (login, logout, failures)
  - Electric sync errors
  - RLS violations
  - Performance bottlenecks

- [ ] **Alerts**
  - High auth failure rate
  - Electric sync unavailable
  - Database connection exhaustion
  - Slow RLS queries

## Known Limitations & Future Work

### Current Limitations

1. **No Token Refresh**: Tokens expire after 14 days, requires re-login
2. **localStorage Security**: Tokens in localStorage vulnerable to XSS
3. **No Optimistic Mutations**: Writes go directly to backend
4. **Single Database**: Both apps on same Postgres instance

### Future Enhancements

1. **Token Refresh Flow**
   - Refresh tokens with longer lifetime
   - Auto-refresh before expiry
   - Sliding window sessions

2. **HttpOnly Cookies**
   - Move tokens from localStorage to HttpOnly cookies
   - Add CSRF protection
   - More secure against XSS

3. **Optimistic Mutations**
   - Local-first writes with TanStack DB
   - Conflict resolution
   - Offline queue

4. **Role-Based Access Control (RBAC)**
   - Use `role` claim from JWT
   - Backend policies by role
   - Frontend UI based on permissions

5. **Audit Logging**
   - Track all data mutations
   - Who accessed what, when
   - Compliance requirements

6. **Database Sharding** (Future)
   - Separate databases per tenant
   - Route connections by org_id
   - Scale horizontally

## Success Criteria

- ✅ RLS migration runs successfully
- ✅ JWT authentication works end-to-end
- ✅ Electric shapes sync with org_id filtering
- ✅ Multi-tenant isolation verified (3 layers)
- ✅ Unit tests pass
- ✅ Integration tests pass
- ✅ Documentation updated
- ✅ Ready for production deployment

## Next Session Ideas

After completing Phase 3, consider:
- **Domain Implementation**: Build out Control management features
- **UI Development**: Create frontend components for controls
- **2x2 Quadrant Dashboard**: Visualize control classifications
- **Provider Network Graph**: Build provider distance calculations
- **Production Deployment**: Deploy to infrastructure project

## Resources

- **Session Doc**: `.claude/sessions/2025-11-15-phase2-electricsql-client-integration.md`
- **Issue**: https://github.com/shotleybuilder/sertantai-controls/issues/1 (closed)
- **Auth Service**: `~/Desktop/sertantai_auth`
- **Electric Docs**: Frontend README at `src/lib/electric/README.md`

---

**Note:** This session focuses on testing what was built in Phase 2 and adding production-ready features. Start with database migration and basic testing, then add enhancements as needed.
