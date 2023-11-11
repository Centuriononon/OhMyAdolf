# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :oh_my_adolf,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :oh_my_adolf, OhMyAdolfWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: OhMyAdolfWeb.ErrorHTML, json: OhMyAdolfWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: OhMyAdolf.PubSub,
  live_view: [signing_salt: "NLHuBSjH"]

config :oh_my_adolf,
  scout: OhMyAdolf.Scout,
  graph_repo: OhMyAdolf.GraphRepo,
  crawler: OhMyAdolf.Crawler,
  crawling: [
    api_client: OhMyAdolf.Wiki.APIClient,
    scraper: OhMyAdolf.Wiki.Scraper,
    scraping_limit: 200,
    scraping_timeout: 10_000
  ],
  core_url: "https://en.wikipedia.org/wiki/Adolf_Hitler",
  wiki_api: [
    host: "en.wikipedia.org",
    http_client: OhMyAdolf.PoisonProxy,
    rate_per_sec: 200
  ],
  poison_proxy: [
    timeout: :infinity,
    http_client: HTTPoison,
    throttle: OhMyAdolf.PoisonProxy
  ]

config :bolt_sips, Bolt,
  url: "bolt://localhost:7687",
  basic_auth: [
    username: System.get_env("NEO4J_USERNAME", "neo4j"),
    password: System.get_env("NEO4J_PASSWORD", "pass")
  ]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
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
