defmodule OhMyAdolf.CrawlerHelpers do
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
      # max concurency is the rate of the proxy actually
      max_concurency: config.max_concurency,
      on_timeout: :kill_task,
      timeout: 20_000
    )
    |> Stream.flat_map(& &1)
    |> Enum.to_list()
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
      {:ok, sub_urls_s}
    else
      err ->
        {:error, {url, err}}
    end
  end

  def validate_config!(config) do
    %{
      max_concurency: config[:max_concurency] || 50,
      api_client: validate_as_req!(config, :api_client),
      scraper: validate_as_req!(config, :scraper)
    }
  end

  def validate_as_req!(config, key) do
    config[key] || raise ArgumentError.exception("#{inspect(key)} arg is required")
  end
end
