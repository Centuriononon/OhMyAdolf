import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/oh_my_adolf start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :oh_my_adolf, OhMyAdolfWeb.Endpoint, server: true
end

IO.puts "Configuring in #{config_env()} mode"

if config_env() == :prod do
  db_url =
    System.get_env("NEO4J_BOLT_URL") ||
      raise "environment variable NEO4J_BOLT_URL is missing"

  db_username =
    System.get_env("NEO4J_USERNAME") ||
      raise "environment variable NEO4J_USERNAME is missing"

  db_password =
    System.get_env("NEO4J_PASSWORD") ||
      raise "environment variable NEO4J_PASSWORD is missing"

  config :bolt_sips, Bolt,
    url: db_url,
    timeout: 45_000,
    retry_linear_backoff: [delay: 150, factor: 2, tries: 3],
    pool_size: 20,
    basic_auth: [
      username: db_username,
      password: db_password
    ]

  if System.get_env("PHX_SERVER") do
    config :oh_my_adolf, OhMyAdolfWeb.Endpoint, server: true
  end

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("HTTP_PORT") || "4000")

  config :oh_my_adolf, OhMyAdolfWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {127, 0, 0, 1},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :oh_my_adolf, OhMyAdolfWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :oh_my_adolf, OhMyAdolfWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
