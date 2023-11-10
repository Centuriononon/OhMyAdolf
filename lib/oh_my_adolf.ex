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
      scraper: validate!(config, :scraper)
    }

    OhMyAdolf.Crawler.crawl(url, config)
    |> Enum.find(get_url_handler(seeking_url))
  end

  defp get_url_handler(seeking_url) do
    fn
      {:ok, ^seeking_url} ->
        Logger.info("Found the seeking url")
        true

      {:ok, abv_url, ^seeking_url} ->
        Logger.info("Found the seeking url from #{abv_url}")
        true

      {:ok, fst_url} ->
        Logger.info("Skipping the first url: #{fst_url}")
        false

      {:ok, abv_url, url} ->
        Logger.info("Skipping #{url} --from--> #{abv_url}")
        false

      {:error, {url, {:error, reason}}} ->
        Logger.error("Could not process #{url} due to #{reason}")
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
end
