defmodule SertantaiControlsWeb.Plugs.VerifyAuthToken do
  @moduledoc """
  Plug to verify JWT tokens from sertantai-auth and load the current user.

  Uses Joken to verify JWT signature with SHARED_TOKEN_SECRET.
  Extracts user_id from 'sub' claim, org_id and role from custom claims.
  Loads user from shared database and assigns context to conn.

  ## Assigns

  On successful verification, assigns the following to conn:
  - `:current_user` - The loaded User resource
  - `:current_user_id` - The user's UUID
  - `:current_org_id` - The user's organization UUID
  - `:current_role` - The user's role atom (:owner, :admin, :member, :viewer)
  """

  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        verify_token_and_load_user(conn, token)

      _ ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "Missing or invalid authorization header"})
        |> halt()
    end
  end

  defp verify_token_and_load_user(conn, token) do
    secret = Application.fetch_env!(:sertantai_controls, :token_signing_secret)

    if is_nil(secret) do
      Logger.error("SHARED_TOKEN_SECRET is not configured")

      conn
      |> put_status(:internal_server_error)
      |> Phoenix.Controller.json(%{error: "Authentication not configured"})
      |> halt()
    else
      signer = Joken.Signer.create("HS256", secret)

      case Joken.verify(token, signer) do
        {:ok, claims} ->
          with {:ok, user_id} <- extract_user_id(claims["sub"]),
               {:ok, org_id} <- extract_org_id(claims["org_id"]),
               {:ok, role} <- extract_role(claims["role"]),
               {:ok, user} <- load_user(user_id),
               :ok <- set_tenant_context(org_id) do
            conn
            |> assign(:current_user, user)
            |> assign(:current_user_id, user_id)
            |> assign(:current_org_id, org_id)
            |> assign(:current_role, role)
          else
            {:error, reason} ->
              Logger.warning("Token verification failed: #{inspect(reason)}")

              conn
              |> put_status(:unauthorized)
              |> Phoenix.Controller.json(%{error: "Invalid token: #{reason}"})
              |> halt()
          end

        {:error, reason} ->
          Logger.warning("JWT verification failed: #{inspect(reason)}")

          conn
          |> put_status(:unauthorized)
          |> Phoenix.Controller.json(%{error: "Invalid or expired token"})
          |> halt()
      end
    end
  end

  # Extract user ID from AshAuthentication 'sub' claim
  # Format: "user?id=<uuid>"
  defp extract_user_id("user?id=" <> user_id) when is_binary(user_id) do
    {:ok, user_id}
  end

  defp extract_user_id(sub) do
    Logger.warning("Invalid sub claim format: #{inspect(sub)}")
    {:error, "invalid_user_id"}
  end

  # Extract organization ID from custom 'org_id' claim
  defp extract_org_id(org_id) when is_binary(org_id) do
    {:ok, org_id}
  end

  defp extract_org_id(nil) do
    Logger.warning("Missing org_id claim in token")
    {:error, "missing_org_id"}
  end

  defp extract_org_id(org_id) do
    Logger.warning("Invalid org_id claim format: #{inspect(org_id)}")
    {:error, "invalid_org_id"}
  end

  # Extract role from custom 'role' claim
  # Convert string to atom
  defp extract_role(role) when is_binary(role) do
    role_atom =
      case role do
        "owner" -> :owner
        "admin" -> :admin
        "member" -> :member
        "viewer" -> :viewer
        other -> String.to_existing_atom(other)
      end

    {:ok, role_atom}
  rescue
    ArgumentError ->
      Logger.warning("Invalid role: #{inspect(role)}")
      {:error, "invalid_role"}
  end

  defp extract_role(nil) do
    Logger.warning("Missing role claim in token")
    {:error, "missing_role"}
  end

  defp extract_role(role) do
    Logger.warning("Invalid role claim format: #{inspect(role)}")
    {:error, "invalid_role"}
  end

  # Load user from shared database
  # Note: User resource should exist in SertantaiControls.Auth.User
  defp load_user(user_id) when is_binary(user_id) do
    # TODO: Replace with actual Ash resource path when User resource is created
    # For now, assume SertantaiControls.Auth.User exists
    case Ash.get(SertantaiControls.Auth.User, user_id) do
      {:ok, user} ->
        {:ok, user}

      {:error, %Ash.Error.Query.NotFound{}} ->
        Logger.warning("User not found: #{user_id}")
        {:error, "user_not_found"}

      {:error, error} ->
        Logger.error("Failed to load user: #{inspect(error)}")
        {:error, "failed_to_load_user"}
    end
  end

  defp load_user(_) do
    {:error, "invalid_user_id"}
  end

  # Set tenant context in database session for RLS policies
  # This calls the set_current_org_id() PostgreSQL function
  defp set_tenant_context(org_id) when is_binary(org_id) do
    query = "SELECT set_current_org_id($1::uuid)"

    case Ecto.Adapters.SQL.query(SertantaiControls.Repo, query, [org_id]) do
      {:ok, _result} ->
        Logger.debug("Tenant context set: #{org_id}")
        :ok

      {:error, error} ->
        Logger.error("Failed to set tenant context: #{inspect(error)}")
        {:error, "failed_to_set_tenant_context"}
    end
  end

  defp set_tenant_context(_) do
    {:error, "invalid_org_id"}
  end
end
