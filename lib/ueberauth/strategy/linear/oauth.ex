defmodule Ueberauth.Strategy.Linear.OAuth do
  @moduledoc false

  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://api.linear.app",
    authorize_url: "https://linear.app/oauth/authorize",
    token_url: "https://api.linear.app/oauth/token"
  ]

  def client(opts \\ []) do
    linear_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Linear.OAuth)

    client_opts =
      @defaults
      |> Keyword.merge(linear_config)
      |> Keyword.merge(opts)

    json_library = Ueberauth.json_library()

    client_opts
    |> OAuth2.Client.new()
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  def get(token, url, params \\ %{}, headers \\ [], opts \\ []) do
    url =
      []
      |> client()
      |> to_url(url, params)

    headers = headers_with_auth(token, headers)

    OAuth2.Client.get(client(), url, headers, opts)
  end

  def post(token, url, params \\ %{}, headers \\ [], opts \\ []) do
    headers = headers_with_auth(token, headers)
    url = endpoint(url, client())

    client()
    |> put_header("Accept", "application/json")
    |> put_header("Content-Type", "application/json")
    |> OAuth2.Client.post(url, params, headers, opts)
  end

  defp headers_with_auth(token, headers),
    do: [{"Authorization", "Bearer #{token.access_token}"} | headers]

  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> OAuth2.Client.authorize_url!(params)
  end

  def get_token!(params \\ [], opts \\ []) do
    headers = Map.get(opts, :headers, [])
    options = Map.get(opts, :options, [])
    client_options = Keyword.get(options, :client_options, [])

    client = OAuth2.Client.get_token!(client(client_options), params, headers, options)

    client.token
  end

  # Strategy callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  defp endpoint("/" <> _path = endpoint, client), do: client.site <> endpoint
  defp endpoint(endpoint, _client), do: endpoint

  defp to_url(client, endpoint, params) do
    client_endpoint =
      client
      |> Map.get(:endpoint, endpoint)
      |> endpoint(client)

    build_final_endpoint(client_endpoint, params)
  end

  defp build_final_endpoint(endpoint, nil), do: endpoint

  defp build_final_endpoint(endpoint, params) do
    endpoint <> "?" <> URI.encode_query(params)
  end
end
