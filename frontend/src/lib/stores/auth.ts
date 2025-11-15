/**
 * Authentication store for managing JWT tokens and user session
 *
 * This store:
 * - Persists JWT token in localStorage
 * - Provides reactive user state
 * - Extracts user data from JWT claims
 * - Manages login/logout flow
 */

import { writable, derived } from 'svelte/store';
import { browser } from '$app/environment';

const TOKEN_KEY = 'auth_token';
const USER_KEY = 'user_data';

export interface User {
	id: string;
	email: string;
	organization_id: string;
	role: 'owner' | 'admin' | 'member' | 'viewer';
}

export interface AuthState {
	token: string | null;
	user: User | null;
	isAuthenticated: boolean;
}

// Initialize from localStorage if in browser
function getInitialState(): AuthState {
	if (!browser) {
		return { token: null, user: null, isAuthenticated: false };
	}

	const token = localStorage.getItem(TOKEN_KEY);
	const userData = localStorage.getItem(USER_KEY);

	if (token && userData) {
		try {
			const user = JSON.parse(userData) as User;
			return { token, user, isAuthenticated: true };
		} catch {
			// Invalid data in localStorage, clear it
			localStorage.removeItem(TOKEN_KEY);
			localStorage.removeItem(USER_KEY);
			return { token: null, user: null, isAuthenticated: false };
		}
	}

	return { token: null, user: null, isAuthenticated: false };
}

// Create the auth store
function createAuthStore() {
	const { subscribe, set, update } = writable<AuthState>(getInitialState());

	return {
		subscribe,

		/**
		 * Set authentication state after successful login
		 * @param token - JWT token from sertantai-auth
		 * @param user - User data from login response
		 */
		login(token: string, user: User) {
			if (browser) {
				localStorage.setItem(TOKEN_KEY, token);
				localStorage.setItem(USER_KEY, JSON.stringify(user));
			}
			set({ token, user, isAuthenticated: true });
		},

		/**
		 * Clear authentication state on logout
		 */
		logout() {
			if (browser) {
				localStorage.removeItem(TOKEN_KEY);
				localStorage.removeItem(USER_KEY);
			}
			set({ token: null, user: null, isAuthenticated: false });
		},

		/**
		 * Update the token (e.g., after refresh)
		 */
		updateToken(token: string) {
			if (browser) {
				localStorage.setItem(TOKEN_KEY, token);
			}
			update((state) => ({ ...state, token }));
		}
	};
}

export const auth = createAuthStore();

// Derived store for just the token (useful for API calls)
export const authToken = derived(auth, ($auth) => $auth.token);

// Derived store for just the user
export const currentUser = derived(auth, ($auth) => $auth.user);

// Derived store for org_id (useful for Electric client)
export const currentOrgId = derived(auth, ($auth) => $auth.user?.organization_id || null);
