import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :oh_my_adolf, OhMyAdolfWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "+3xgnhloolyfPiYp//CuedwP829wDOc7O4wgFsZirT4KBKUbVWHHz+7uZ6eoDN6z",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]

# Watch static and templates for browser reloading.
config :oh_my_adolf, OhMyAdolfWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/oh_my_adolf_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :oh_my_adolf, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Include HEEx debug annotations as HTML comments in rendered markup
config :phoenix_live_view, :debug_heex_annotations, true


config :bolt_sips, Bolt,
  url: System.get_env("NEO4J_URL"),
  timeout: 45_000,
  retry_linear_backoff: [delay: 150, factor: 2, tries: 3],
  pool_size: 20,
  basic_auth: [
    username: System.get_env("NEO4J_USERNAME"),
    password: System.get_env("NEO4J_PASSWORD")
  ]
