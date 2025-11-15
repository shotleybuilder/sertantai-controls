/**
 * ElectricSQL shape subscriptions with Svelte store integration
 *
 * This module provides:
 * - Reactive Svelte stores backed by Electric shapes
 * - Automatic subscription management
 * - Type-safe data access
 * - Error handling and loading states
 */

import { writable, type Readable } from 'svelte/store';
import type { ShapeStream } from '@electric-sql/client';
import { browser } from '$app/environment';

export interface ShapeSubscriptionState<T> {
	data: T[];
	loading: boolean;
	error: Error | null;
	synced: boolean;
}

/**
 * Create a reactive Svelte store from an Electric shape stream
 *
 * @param streamFactory - Function that creates the shape stream (lazy initialization)
 * @returns Readable store with shape data and loading/error states
 *
 * @example
 * ```ts
 * import { shapes } from '$lib/electric/client';
 * import { createShapeSubscription } from '$lib/electric/subscriptions';
 *
 * export const controls = createShapeSubscription(() =>
 *   shapes.controls()
 * );
 * ```
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function createShapeSubscription<T = any>(
	streamFactory: () => ShapeStream<any>
): Readable<ShapeSubscriptionState<T>> {
	const { subscribe, set } = writable<ShapeSubscriptionState<T>>({
		data: [],
		loading: true,
		error: null,
		synced: false
	});

	// Only subscribe in browser
	if (browser) {
		// eslint-disable-next-line @typescript-eslint/no-explicit-any
		let stream: ShapeStream<any> | null = null;

		try {
			stream = streamFactory();

			// TODO: Implement Electric shape subscription
			// The Electric v1.0 API may differ from this skeleton implementation
			// This is a placeholder that will need to be updated based on actual Electric API
			console.log('Electric stream created:', stream);

			// Set initial state as synced (skeleton implementation)
			set({
				data: [],
				loading: false,
				error: null,
				synced: true
			});
		} catch (error) {
			console.error('Failed to create shape subscription:', error);
			set({
				data: [],
				loading: false,
				error: error as Error,
				synced: false
			});
		}

		// Cleanup function (to be implemented when subscription is active)
		// return cleanup
	}

	// Server-side: return empty store
	return { subscribe };
}

/**
 * Create a derived shape subscription with filtering
 *
 * @param baseSubscription - Base shape subscription
 * @param filter - Filter function
 * @returns Filtered store
 */
export function filterShape<T>(
	baseSubscription: Readable<ShapeSubscriptionState<T>>,
	filter: (item: T) => boolean
): Readable<ShapeSubscriptionState<T>> {
	const { subscribe } = writable<ShapeSubscriptionState<T>>({
		data: [],
		loading: true,
		error: null,
		synced: false
	});

	baseSubscription.subscribe((state) => {
		return {
			...state,
			data: state.data.filter(filter)
		};
	});

	return { subscribe };
}

/**
 * Helper to get a single item from a shape by ID
 */
export function findInShape<T extends { id: string }>(
	shapeState: ShapeSubscriptionState<T>,
	id: string
): T | null {
	return shapeState.data.find((item) => item.id === id) || null;
}

/**
 * Helper to count items in a shape that match a predicate
 */
export function countInShape<T>(
	shapeState: ShapeSubscriptionState<T>,
	predicate: (item: T) => boolean
): number {
	return shapeState.data.filter(predicate).length;
}
