defmodule SertantaiControlsWeb.ElectricController do
  @moduledoc """
  Controller for proxying ElectricSQL shape requests with authentication.

  This controller:
  1. Receives authenticated shape requests from frontend
  2. Extracts org_id from JWT claims (set by VerifyAuthToken plug)
  3. Adds tenant filtering to shape requests
  4. Proxies requests to ElectricSQL service

  All shapes are automatically filtered by the user's organization_id
  to ensure multi-tenant data isolation.
  """

  use SertantaiControlsWeb, :controller
  require Logger

  @doc """
  Handles ElectricSQL HTTP shape sync requests.

  This endpoint proxies requests to the ElectricSQL service while ensuring
  tenant isolation by adding organization_id filters to all shape requests.

  ## Query Parameters
  - `table` - The table name to sync
  - `offset` - Sync offset (optional)
  - `live` - Whether to keep connection alive for live updates (optional)
  - Other ElectricSQL shape parameters...

  ## Headers
  - `Authorization: Bearer <jwt>` - Required (handled by VerifyAuthToken plug)

  ## Response
  - Proxies the ElectricSQL shape response directly to the client
  - Content-Type: application/json or text/event-stream (for live mode)
  """
  def sync(conn, params) do
    org_id = conn.assigns.current_org_id
    user_id = conn.assigns.current_user_id

    Logger.info(
      "Electric sync request - User: #{user_id}, Org: #{org_id}, Table: #{params["table"]}"
    )

    # Get Electric service URL from config
    electric_url = get_electric_url()

    # Build the proxied URL with tenant filtering
    case build_electric_request(electric_url, params, org_id) do
      {:ok, url, headers} ->
        proxy_to_electric(conn, url, headers)

      {:error, reason} ->
        Logger.error("Failed to build Electric request: #{inspect(reason)}")

        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid shape request", reason: inspect(reason)})
    end
  end

  # Build the Electric request URL with tenant filtering
  defp build_electric_request(base_url, params, org_id) do
    table = params["table"]

    if is_nil(table) do
      {:error, :missing_table_parameter}
    else
      # Add organization_id filter to WHERE clause
      # Electric v1.0 uses 'where' parameter for filtering
      where_clause = build_where_clause(params["where"], org_id)

      # Build query parameters
      query_params =
        params
        |> Map.drop(["table"])
        |> Map.put("where", where_clause)
        |> URI.encode_query()

      # Build full URL
      url = "#{base_url}/v1/shape/#{table}?#{query_params}"

      # Headers to pass through
      headers = [
        {"Accept", "application/json"}
      ]

      {:ok, url, headers}
    end
  end

  # Build WHERE clause with organization_id filter
  defp build_where_clause(existing_where, org_id) do
    org_filter = "organization_id = '#{org_id}'"

    case existing_where do
      nil ->
        org_filter

      "" ->
        org_filter

      where when is_binary(where) ->
        # Combine existing WHERE with org filter using AND
        "#{org_filter} AND (#{where})"
    end
  end

  # Proxy the request to Electric service
  defp proxy_to_electric(conn, url, headers) do
    Logger.debug("Proxying to Electric: #{url}")

    # Use HTTPoison or Req to proxy the request
    # For now, using :httpc (built-in Erlang HTTP client)
    case :httpc.request(:get, {String.to_charlist(url), headers}, [], []) do
      {:ok, {{_, status_code, _}, response_headers, body}} ->
        Logger.debug("Electric response: #{status_code}")

        # Convert headers to Phoenix format
        phoenix_headers =
          Enum.map(response_headers, fn {key, value} ->
            {to_string(key), to_string(value)}
          end)

        conn
        |> merge_resp_headers(phoenix_headers)
        |> send_resp(status_code, body)

      {:error, reason} ->
        Logger.error("Electric request failed: #{inspect(reason)}")

        conn
        |> put_status(:bad_gateway)
        |> json(%{error: "Failed to connect to Electric service", reason: inspect(reason)})
    end
  end

  # Get Electric service URL from config
  defp get_electric_url do
    System.get_env("ELECTRIC_URL") || "http://localhost:5133"
  end
end
