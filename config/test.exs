import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :oh_my_adolf, OhMyAdolfWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base:
    "CI1SuK2CPETxv/9R/jyd8aJXGyCnqtswMxsaWjRWt2+l2tFjgywFcx4zD5sUufs/",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
