defmodule OhMyAdolf do
  @moduledoc """
  OhMyAdolf keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require Logger
  alias __MODULE__

  # Long: "https://en.wikipedia.org/wiki/Schutzstaffel" |> URI.parse |> OhMyAdolf.find_path()
  # Short: "https://en.wikipedia.org/wiki/Nazism" |> URI.parse |> OhMyAdolf.find_path()
  def find_path(%URI{} = url, config \\ default_config()) do
    seeking_url = validate!(config, :seeking_url) |> URI.parse()
    config = %{
      api_client: validate!(config, :api_client),
      scraper: validate!(config, :scraper),
    }

    OhMyAdolf.Crawler.crawl(url, config)
    |> Enum.find(get_url_handler(seeking_url))
  end

  defp get_url_handler(seeking_url) do
    seeking_path = seeking_url.path

    fn
      {abv_url, %URI{path: ^seeking_path}} ->
        Logger.info("Found the seeking url from #{abv_url}")
        true

      {abv_url, url} ->
        Logger.notice("Skip: #{url} from #{abv_url}")
        false
    end
  end

  def default_config do
    Application.get_env(:oh_my_adolf, :crawling, [])
  end

  def validate!(config, :seeking_url) do
    Keyword.get(config, :seeking_url) || "https://en.wikipedia.org/wiki/Adolf_Hitler"
  end

  def validate!(config, :api_client) do
    Keyword.get(config, :api_client) || Wiki.APIClient
  end

  def validate!(config, :scraper) do
    Keyword.get(config, :scraper) || Wiki.Scraper
  end

  def validate!(config, :max_concurency) do
    Keyword.get(config, :max_concurency) || 200
  end
end
