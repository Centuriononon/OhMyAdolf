defmodule OhMyAdolf.CrawlerHelpers do
  require Logger

  def scraped_urls(urls, config) do
    Task.Supervisor.async_stream(
      OhMyAdolf.TaskSupervisor,
      urls,
      fn url ->
        url
        |> scraped_url(config)
        |> Stream.map(fn sub_url -> {url, sub_url} end)
        |> Enum.to_list()
      end,
      max_concurency: config.chunks,
      on_timeout: :kill_task,
      timeout: 20_000
    )
    |> Stream.flat_map(fn
      {:ok, urls} -> urls
      _ -> []
    end)
  end

  def scraped_url(url, config) do
    case scrape(url, config) do
      {:ok, sub_urls_s} -> sub_urls_s
      _ -> []
    end
  end

  def scrape(url, config) do
    with(
      {:ok, page} <- config.api_client.fetch_page(url),
      {:ok, sub_urls_s} <- config.scraper.uniq_urls(page)
    ) do
      Logger.debug("Scraped #{url}")
      {:ok, sub_urls_s}
    else
      {:error, reason} ->
        Logger.warn("Could not scrape #{url} due to #{inspect(reason)}")
        {:error, {url, reason}}
    end
  end

  def validate_config!(config) do
    %{
      chunks: config[:chunks] || 50,
      api_client: validate_as_req!(config, :api_client),
      scraper: validate_as_req!(config, :scraper)
    }
  end

  def validate_as_req!(config, key) do
    config[key] ||
      raise ArgumentError.exception("#{inspect(key)} arg is required")
  end
end
