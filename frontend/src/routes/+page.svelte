<script lang="ts">
	import { onMount } from 'svelte';

	let message = '';
	let status = '';
	let error = '';
	let loading = true;

	const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000';

	async function fetchHello() {
		loading = true;
		error = '';

		try {
			const response = await fetch(`${API_URL}/api/hello`);
			if (!response.ok) {
				throw new Error(`HTTP error! status: ${response.status}`);
			}
			const data = await response.json();
			message = data.message;
			status = 'success';
		} catch (e) {
			error = e instanceof Error ? e.message : 'Unknown error';
			status = 'error';
		} finally {
			loading = false;
		}
	}

	onMount(() => {
		fetchHello();
	});
</script>

<main>
	<h1>Sertantai Controls</h1>

	<div class="card">
		<h2>Backend API Test</h2>

		{#if loading}
			<p class="loading">Loading...</p>
		{:else if status === 'success'}
			<p class="success">{message}</p>
		{:else if error}
			<p class="error">Error: {error}</p>
		{/if}

		<button on:click={fetchHello} disabled={loading}> Refresh </button>
	</div>

	<div class="info">
		<p>API URL: <code>{API_URL}</code></p>
	</div>
</main>

<style>
	main {
		text-align: center;
		padding: 2rem;
		max-width: 800px;
		margin: 0 auto;
		font-family:
			-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans',
			'Helvetica Neue', sans-serif;
	}

	h1 {
		color: #333;
		font-size: 2.5rem;
		margin-bottom: 2rem;
	}

	h2 {
		color: #555;
		font-size: 1.5rem;
		margin-bottom: 1rem;
	}

	.card {
		background: white;
		border-radius: 8px;
		padding: 2rem;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
		margin-bottom: 1rem;
	}

	.loading {
		color: #666;
		font-style: italic;
	}

	.success {
		color: #28a745;
		font-weight: 600;
	}

	.error {
		color: #dc3545;
		font-weight: 600;
	}

	button {
		background: #007bff;
		color: white;
		border: none;
		padding: 0.75rem 1.5rem;
		font-size: 1rem;
		border-radius: 4px;
		cursor: pointer;
		margin-top: 1rem;
	}

	button:hover:not(:disabled) {
		background: #0056b3;
	}

	button:disabled {
		background: #ccc;
		cursor: not-allowed;
	}

	.info {
		margin-top: 2rem;
		padding: 1rem;
		background: #f8f9fa;
		border-radius: 4px;
	}

	code {
		background: #e9ecef;
		padding: 0.2rem 0.4rem;
		border-radius: 3px;
		font-family: 'Courier New', monospace;
	}

	:global(body) {
		margin: 0;
		background: #f5f5f5;
	}
</style>
