/**
 * ElectricSQL client setup with JWT authentication
 *
 * This module configures the Electric client to:
 * - Connect to the backend Electric sync endpoint
 * - Automatically include JWT token in requests
 * - Handle authentication errors
 * - Provide tenant-scoped data sync
 */

import { ShapeStream } from '@electric-sql/client';
import { get } from 'svelte/store';
import { authToken } from '$lib/stores/auth';
import { browser } from '$app/environment';

/**
 * Base URL for Electric sync endpoint
 * Points to our backend which proxies to Electric with org_id filtering
 */
const ELECTRIC_URL = browser
	? `${window.location.protocol}//${window.location.hostname}:4000/api/electric/sync`
	: 'http://localhost:4000/api/electric/sync';

/**
 * Create an authenticated Electric shape stream
 *
 * @param params - Shape parameters (table, where clause, etc.)
 * @returns ShapeStream configured with authentication
 *
 * @example
 * ```ts
 * const stream = createAuthenticatedShape({
 *   table: 'controls',
 *   where: 'current_quadrant = "strange"'
 * });
 * ```
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unused-vars
export function createAuthenticatedShape<T = any>(params: {
	table: string;
	where?: string;
	columns?: string[];
	replica?: 'default' | 'full';
}): ShapeStream<any> {
	const token = get(authToken);

	if (!token) {
		throw new Error('Cannot create shape: user not authenticated');
	}

	// Build query parameters
	const queryParts: string[] = [`table=${encodeURIComponent(params.table)}`];

	if (params.where) {
		queryParts.push(`where=${encodeURIComponent(params.where)}`);
	}

	if (params.columns) {
		queryParts.push(`columns=${encodeURIComponent(params.columns.join(','))}`);
	}

	if (params.replica) {
		queryParts.push(`replica=${encodeURIComponent(params.replica)}`);
	}

	const queryString = queryParts.join('&');

	// Create shape stream with authentication headers
	const stream = new ShapeStream<any>({
		url: `${ELECTRIC_URL}?${queryString}`,
		headers: {
			Authorization: `Bearer ${token}`
		},
		// Handle auth errors
		fetchClient: async (input, init) => {
			const response = await fetch(input, init);

			// If unauthorized, user needs to re-authenticate
			if (response.status === 401) {
				console.error('Electric sync: Authentication failed');
				// Optionally: trigger logout or token refresh
				// auth.logout();
			}

			return response;
		}
	});

	return stream;
}

/**
 * Helper to create a shape for a specific table with common configuration
 */
export const shapes = {
	/**
	 * Get controls shape
	 * Automatically filtered by organization_id on backend
	 */
	controls(where?: string) {
		return createAuthenticatedShape({
			table: 'controls',
			where,
			replica: 'full'
		});
	},

	/**
	 * Get control interactions shape
	 */
	controlInteractions(controlId?: string) {
		const where = controlId ? `control_id = '${controlId}'` : undefined;
		return createAuthenticatedShape({
			table: 'control_interactions',
			where
		});
	},

	/**
	 * Get control providers shape
	 */
	controlProviders() {
		return createAuthenticatedShape({
			table: 'control_providers',
			replica: 'full'
		});
	},

	/**
	 * Get quadrant classifications shape
	 */
	quadrantClassifications(controlId?: string) {
		const where = controlId ? `control_id = '${controlId}'` : undefined;
		return createAuthenticatedShape({
			table: 'quadrant_classifications',
			where
		});
	}
};

/**
 * Check if Electric client is properly configured
 */
export function isElectricConfigured(): boolean {
	return !!ELECTRIC_URL && !!get(authToken);
}

/**
 * Get Electric sync status
 */
export function getElectricStatus() {
	const token = get(authToken);
	return {
		configured: !!ELECTRIC_URL,
		authenticated: !!token,
		url: ELECTRIC_URL
	};
}
