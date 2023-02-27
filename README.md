# Überauth Linear

> Linear strategy for Überauth.

## Installation

1. Setup your application in [Linear](https://linear.app/settings/api/applications/new).

2. Add `:ueberauth_linear` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ueberauth_linear, "~> 0.2"}
  ]
end
```

3. Add Linear to your Überauth configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    linear: {Ueberauth.Strategy.Linear, []}
  ]
```

4. Update your provider configuration:

```elixir
config :ueberauth, Ueberauth.Strategy.Linear.OAuth,
  client_id: System.get_env("LINEAR_CLIENT_ID"),
  client_secret: System.get_env("LINEAR_CLIENT_SECRET")
```

5.  Include the Überauth plug in your controller:

```elixir
defmodule MyApp.AuthController do
  use MyApp.Web, :controller
  plug Ueberauth
  ...
end
```

6.  Create the request and callback routes if you haven't already:

```elixir
scope "/auth", MyApp do
  pipe_through :browser

  get "/:provider", AuthController, :request
  get "/:provider/callback", AuthController, :callback
end
```

7. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

```
/auth/linear
```

## Development mode

As noted when registering your application on the Linear site, you need to explicitly specify the `oauth_callback` url. While in development, this is an example url you need to enter.

    Website - http://127.0.0.1
    Callback URL - http://127.0.0.1:4000/auth/linear/callback

## License

Please see [LICENSE](https://github.com/withbroadcast/ueberauth_linear/blob/master/LICENSE) for licensing details.
