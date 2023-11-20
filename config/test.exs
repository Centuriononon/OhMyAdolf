import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :oh_my_adolf, OhMyAdolfWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "01eGUvWvrhjvfUCaTmLCAvdehJDTUcQGJVXyBxU4ncvVvwU2bIsMqbehAFAKIIPl",
  server: false

config :oh_my_adolf, :wiki,
  host: "en.wikipedia.org",
  http_client: OhMyAdolf.HTTPClientMock,
  wiki_url: OhMyAdolf.Wiki.WikiURLMock,
  parser: OhMyAdolf.Wiki.ParserMock,
  fetcher: OhMyAdolf.Wiki.FetcherMock,
  scraper: OhMyAdolf.Wiki.ScraperMock,
  scraping_timeout: 1000,
  scraping_chunks: 10,
  http_options: [follow_redirect: true],
  http_headers: [{"User-Agent", "UserAgentTest"}]

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
