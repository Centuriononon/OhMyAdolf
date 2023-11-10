defmodule OhMyAdolf do
  @moduledoc """
  OhMyAdolf keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require Logger

  # Short: "https://en.wikipedia.org/wiki/Nazism" |> URI.parse |> OhMyAdolf.find_path()
  # Long:  "https://en.wikipedia.org/wiki/Adolf_Hitler" |> URI.parse |> OhMyAdolf.find_path(seeking_url: "https://en.wikipedia.org/wiki/Minecraft_(franchise)")
  def find_path(%URI{} = url, config \\ default_config()) do
    seeking_url = validate!(config, :seeking_url) |> URI.parse()

    config = %{
      api_client: validate!(config, :api_client),
      scraper: validate!(config, :scraper),
      chunks: validate!(config, :chunks)
    }

    case url do
      ^seeking_url ->
        {:ok, [url]}

      _ ->
        OhMyAdolf.Crawler.crawl(url, config)
        |> trace_path(url, seeking_url)
        |> case do
          [] -> {:error, :stub}
          paths -> {:ok, paths}
        end
    end
  end

  defp trace_path(url_stream, url_head, url_tail) do
    url_stream
    |> graph_urls(&check_url(&1, url_tail))
    |> Graph.get_shortest_path(url_head, url_tail) || []
  end

  defp graph_urls(url_stream, check_url) do
    url_stream
    |> Enum.reduce_while(Graph.new(), fn {abv_url, url} = curr, graph ->
      updated_graph =
        graph
        |> Graph.add_edge(Graph.Edge.new(abv_url, url))

      if check_url.(curr) do
        {:halt, updated_graph}
      else
        {:cont, updated_graph}
      end
    end)
  end

  defp check_url({abv_url, url}, url_tail) do
    case url do
      ^url_tail ->
        Logger.info("Found the seeking url going from #{abv_url}")
        true

      _ ->
        Logger.debug("Skip url: #{url}")
        false
    end
  end

  defp default_config do
    Application.get_env(:oh_my_adolf, :crawling, [])
  end

  defp validate!(config, :seeking_url) do
    Keyword.get(config, :seeking_url) || "https://en.wikipedia.org/wiki/Adolf_Hitler"
  end

  defp validate!(config, :api_client) do
    Keyword.get(config, :api_client) || OhMyAdolf.Wiki.APIClient
  end

  defp validate!(config, :scraper) do
    Keyword.get(config, :scraper) || OhMyAdolf.Wiki.Scraper
  end

  defp validate!(config, :chunks) do
    Keyword.get(config, :chunks) || 200
  end
end
