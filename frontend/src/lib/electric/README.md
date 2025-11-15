# ElectricSQL Integration with JWT Authentication

This directory contains the ElectricSQL client setup for sertantai-controls with JWT-based authentication and multi-tenant data isolation.

## Architecture

```
Frontend (Svelte)
  ↓ (HTTP Shape API + JWT)
Backend (Phoenix)
  ↓ (Proxies with org_id filter)
ElectricSQL Service
  ↓ (Logical replication)
PostgreSQL + RLS
```

## Features

- **JWT Authentication**: All Electric requests include JWT token from sertantai-auth
- **Automatic Tenant Filtering**: Backend adds `organization_id` filter to all shapes
- **Row-Level Security**: Database-level isolation via PostgreSQL RLS policies
- **Reactive Stores**: Svelte stores backed by Electric shape streams
- **Type Safety**: Full TypeScript support

## Usage

### 1. Login and Store Token

```typescript
import { auth } from '$lib/stores/auth';

// After successful login to sertantai-auth
const response = await fetch('http://localhost:4000/api/auth/user/password/sign_in', {
	method: 'POST',
	body: JSON.stringify({ email, password })
});

const { token, user } = await response.json();

// Store in auth store
auth.login(token, {
	id: user.id,
	email: user.email,
	organization_id: user.organization_id,
	role: user.role
});
```

### 2. Create Shape Subscriptions

```typescript
import { shapes } from '$lib/electric/client';
import { createShapeSubscription } from '$lib/electric/subscriptions';

// Subscribe to all controls (auto-filtered by org_id)
const controls = createShapeSubscription(() => shapes.controls());

// Subscribe to controls in "strange" quadrant
const strangeControls = createShapeSubscription(() =>
	shapes.controls('current_quadrant = "strange"')
);

// Subscribe to interactions for a specific control
const interactions = createShapeSubscription(() => shapes.controlInteractions('control-uuid-here'));
```

### 3. Use in Svelte Components

```svelte
<script lang="ts">
	import { shapes } from '$lib/electric/client';
	import { createShapeSubscription } from '$lib/electric/subscriptions';

	// Create reactive subscription
	const controlsStore = createShapeSubscription(() => shapes.controls());

	// Reactive statement
	$: controls = $controlsStore.data;
	$: loading = $controlsStore.loading;
	$: error = $controlsStore.error;
</script>

{#if loading}
	<p>Loading controls...</p>
{:else if error}
	<p>Error: {error.message}</p>
{:else}
	<ul>
		{#each controls as control}
			<li>{control.name} - {control.current_quadrant}</li>
		{/each}
	</ul>
{/if}
```

### 4. Pre-built Shape Helpers

```typescript
import { shapes } from '$lib/electric/client';

// All controls (org-scoped)
shapes.controls();

// Controls with WHERE clause
shapes.controls('current_quadrant = "self"');

// Control interactions for a control
shapes.controlInteractions('control-uuid');

// All control providers
shapes.controlProviders();

// Quadrant classifications
shapes.quadrantClassifications();
```

## Environment Variables

Add to `.env.development`:

```bash
PUBLIC_BACKEND_URL=http://localhost:4000
```

## Multi-Tenancy

All data is automatically scoped to the user's organization:

1. **Frontend**: JWT contains `org_id` claim
2. **Backend**: Electric controller extracts `org_id` from JWT
3. **Backend**: Adds `WHERE organization_id = '<org_id>'` to shape requests
4. **Database**: RLS policies enforce row-level isolation
5. **ElectricSQL**: Syncs only tenant-scoped rows

Users can only access data from their organization, enforced at multiple layers.

## Error Handling

```typescript
const subscription = createShapeSubscription(() => shapes.controls());

subscription.subscribe((state) => {
	if (state.error) {
		if (state.error.message.includes('401')) {
			// Token expired or invalid
			auth.logout();
			goto('/login');
		} else {
			// Other error
			console.error('Shape error:', state.error);
		}
	}
});
```

## Testing

```typescript
import { isElectricConfigured, getElectricStatus } from '$lib/electric/client';

// Check if Electric is configured
if (!isElectricConfigured()) {
	console.error('Electric not configured or user not authenticated');
}

// Get detailed status
const status = getElectricStatus();
console.log('Electric status:', status);
// { configured: true, authenticated: true, url: 'http://...' }
```

## Security

- ✅ JWT required for all Electric requests
- ✅ Backend validates JWT signature
- ✅ Automatic org_id filtering on backend
- ✅ PostgreSQL RLS policies as second layer
- ✅ Tokens stored in localStorage (HttpOnly cookies better for production)

## Next Steps

- [ ] Add token refresh logic
- [ ] Implement offline sync detection
- [ ] Add optimistic mutations with TanStack DB
- [ ] Create shape subscription hooks for common patterns
- [ ] Add retry logic for failed syncs
