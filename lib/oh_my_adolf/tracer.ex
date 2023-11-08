defmodule OhMyAdolf.Tracer do
  require Logger
  alias OhMyAdolf.Wiki.{APIClient, Scraper}
  alias OhMyAdolf.Crawler

  def trace(%URI{} = head_url, %URI{} = tail_url, config \\ default_config()) do
    Logger.info("Tracing: #{head_url}, to: #{tail_url}")

    Crawler.crawl_urls(head_url, config)
    |> find_url_leading_to_tail(tail_url)
    |> case do
      :error ->
        {:error, :stub}

      {curr_url, graph} ->
        path = Graph.get_shortest_path(graph, head_url, curr_url)
        :ok = register_path(path)

        path
    end
  end

  defp find_url_leading_to_tail(urls, tail_url) do
    tail_url_str = URI.to_string(tail_url)

    # WARN:
    # Use DB model to determine if we can reach the tail
    # from the current url insteam of the logic below!
    Enum.find(urls, :error, fn {curr_url, _graph} ->
      curr_url_str = URI.to_string(curr_url)

      case curr_url_str do
        ^tail_url_str ->
          Logger.debug("Found the seeking url: #{curr_url_str}")
          true

        _ ->
          Logger.debug("Unknown url: #{curr_url_str}")
          # trace url in the DB
          # if found, then true, else false
          false
      end
    end)
  end

  def register_path(_path) do
    # Register path to DB via a dedicated model

    :ok
  end

  def default_config() do
    %{api_client: APIClient, scraper: Scraper}
  end
end
