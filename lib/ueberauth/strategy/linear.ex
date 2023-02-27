defmodule Ueberauth.Strategy.Linear do
  @moduledoc """
  Linear strategy for Ueberauth.
  """

  use Ueberauth.Strategy,
    uid_field: :id,
    default_scope: "read",
    send_redirect_uri: true,
    oauth2_module: Ueberauth.Strategy.Linear.OAuth

  require Logger

  alias Ueberauth.Auth.{Credentials, Extra, Info}

  @doc """
  Handles initial request for Linear authentication.
  """
  def handle_request!(conn) do
    callback_url = callback_url(conn)

    callback_url =
      if String.ends_with?(callback_url, "?"),
        do: String.slice(callback_url, 0..-2),
        else: callback_url

    opts =
      []
      |> with_scopes(conn)
      |> with_state_param(conn)
      |> Keyword.put(:redirect_uri, callback_url)

    module = option(conn, :oauth2_module)

    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Linear.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    req_headers = conn.req_headers
    Logger.warn("req_headers: #{inspect(req_headers)}")
    resp_headers = conn.resp_headers
    Logger.warn("resp_headers: #{inspect(resp_headers)}")

    module = option(conn, :oauth2_module)
    params = [code: code]
    redirect_uri = get_redirect_uri(conn)

    options = %{
      options: [
        client_options: [redirect_uri: redirect_uri]
      ]
    }

    token = apply(module, :get_token!, [params, options])

    case token.access_token do
      nil ->
        set_errors!(conn, [
          error(token.other_params["error"], token.other_params["error_description"])
        ])

      _ ->
        conn
        |> store_token(token)
        |> fetch_user(token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  defp store_token(conn, token) do
    put_private(conn, :linear_token, token)
  end

  @query """
  {
  	viewer {
  		active
  		admin
  		archivedAt
  		avatarUrl
  		createdAt
  		createdIssueCount
  		disableReason
  		displayName
  		email
  		id
  		lastSeen
  		name
  		updatedAt
  	}
  }
  """

  @fetch_user_params %{"query" => @query}

  defp fetch_user(conn, token) do
    case Ueberauth.Strategy.Linear.OAuth.post(token, "/graphql", @fetch_user_params) do
      {:ok, %OAuth2.Response{status_code: 401}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: body}}
      when status_code in 200..399 ->
        put_private(conn, :linear_user, body["data"]["viewer"])

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  def handle_cleanup!(conn) do
    conn
    |> put_private(:linear_token, nil)
    |> put_private(:linear_user, nil)
  end

  @doc false
  def uid(conn) do
    Map.get(info(conn), option(conn, :uid_field))
  end

  @doc false
  def info(conn) do
    user = conn.private[:linear_user]

    %Info{
      name: user["name"],
      nickname: user["displayName"],
      email: user["email"],
      image: user["avatarUrl"]
    }
  end

  @doc false
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private[:linear_token],
        user: conn.private[:linear_user]
      }
    }
  end

  @doc false
  def credentials(conn) do
    token = conn.private.linear_token
    scopes = token.other_params["scope"] || []
    user = conn.private[:linear_user]

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes,
      other: %{
        user: user
      }
    }
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp get_redirect_uri(%Plug.Conn{} = conn) do
    config = Application.get_env(:ueberauth, Ueberauth)

    case Keyword.get(config, :redirect_uri) do
      nil ->
        callback_url(conn)

      redirect_uri ->
        redirect_uri
    end
  end

  defp with_scopes(opts, conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    Keyword.put(opts, :scope, scopes)
  end
end
