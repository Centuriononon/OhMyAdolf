defmodule OhMyAdolf.Crawler do
  require Logger

  def crawl_urls(%URI{} = url, config) do
    Stream.resource(
      get_init_fn(url, config),
      &handle_next/1,
      get_finish_fn(url)
    )
  end

  defp get_finish_fn(url) do
    Logger.info("Finished streaming for #{url}")
  end

  defp get_init_fn(url, config) do
    Logger.info("Started streaming for #{url}")
    {:init, url, config}
  end

  defp handle_next(:init, url, config) do
    case scrape_re(url, config) do
      {:ok, {_url, suburls_stream}} ->
        url_s = URI.to_string(url)
        graph = Graph.new() |> Graph.add_vertex(url_s, :head)

        {[url, graph], {config, graph, suburls_stream, 0}}
      err ->
        {:halt, [err]}
    end
  end

  defp handle_next({config, graph, urls_stream, i}) do
    urls_stream
    |> Stream.take_while(
      fn
        {:ok, {url, suburls_stream}} ->
          graph = Graph.add_vertex(graph, prev_url, url)
          # The stream is great.
          # But there are constraints.
          # I'd like to navigate by ids, but it looks like it's impossible*.

          # But how can I iterate and emit urls else?
          #   1. Mb just emit the whole lists?

          # Also, how can I iterate the urls only once?
      end
    )
    if i === length(urls_stream) do
      next_urls =
      handle_next({config, graph, next_urls, 0})
    else
      case Task.await(urls[i]) do
        {:ok, {}} ->
      end
      {prev_url, cur_url, urls} =

      graph = Graph.add_vertex(graph, prev_url, url)

      {[cur_url, graph], {config, graph, suburls, i + 1}}
    end
  end

  defp scrape_many_lazy_re(urls, url, config) do
    Stream.map(urls, fn url ->
      suburls_stream = scrape_re(url, config)
      {url, suburls_stream}
    end)
  end

  defp scrape_re(url, config) do
    with {:ok, suburls} <- scrape(url, config) do
      suburls_stream = scrape_many_lazy_re(suburls, url, config)

      {:ok, {url, suburls_stream}}
    end
  end

  defp scrape(url, config) do
    with(
      {:ok, page} <- config.api_client.fetch_page(url),
      {:ok, suburls} <- config.scraper.uniq_urls(page)
    ) do
      {:ok, suburls}
    end
  end

end
