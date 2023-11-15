# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :oh_my_adolf,
  wiki: [
    core_url: "https://en.wikipedia.org/wiki/Adolf_Hitler",
    http_client: OhMyAdolf.PoisonProxy,
    host: "en.wikipedia.org",
    page_registry: OhMyAdolf.WikiURL.Registry
  ]

config :oh_my_adolf,
  poison_proxy: [
    rate_per_sec: 200,
    queue_timeout: :infinity,
    http_client: HTTPoison,
    throttle: OhMyAdolf.PoisonProxy
  ]

config :bolt_sips,
  log: false, # true to log everything
  log_hex: false

config :bolt_sips, Bolt,
  url: "bolt://localhost:7687",
  timeout: 45_000,
  retry_linear_backoff: [delay: 150, factor: 2, tries: 3],
  pool_size: 20,
  basic_auth: [
    username: System.get_env("NEO4J_USERNAME", "neo4j"),
    password: System.get_env("NEO4J_PASSWORD", "pass")
  ]

# Configures the endpoint
config :oh_my_adolf, OhMyAdolfWeb.Endpoint,
  url: [host: "localhost", port: System.get_env("HTTP_PORT") || 4000],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: OhMyAdolfWeb.ErrorHTML, json: OhMyAdolfWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: OhMyAdolf.PubSub,
  live_view: [signing_salt: "lZ3as5fp"]

config :oh_my_adolf,
  generators: [timestamp_type: :utc_datetime]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
