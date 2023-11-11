defmodule OhMyAdolf.CrawlerHelpers do
  require Logger

  @api_client Application.compile_env(
                :oh_my_adolf,
                [:crawling, :api_client],
                OhMyAdolf.Wiki.APIClient
              )
  @scraper Application.compile_env(
             :oh_my_adolf,
             [:crawling, :scraper],
             OhMyAdolf.Wiki.Scraper
           )
  @chunks Application.compile_env(
            :oh_my_adolf,
            [:crawling, :scraping_limit],
            100
          )
  @timeout Application.compile_env(
             :oh_my_adolf,
             [:crawling, :scraping_timeout],
             10_000
           )

  def scraped_urls(urls) do
    Task.Supervisor.async_stream(
      OhMyAdolf.TaskSupervisor,
      urls,
      fn url ->
        url
        |> scraped_url()
        |> Stream.map(fn sub_url -> {url, sub_url} end)
        |> Enum.to_list()
      end,
      max_concurency: @chunks,
      on_timeout: :kill_task,
      timeout: @timeout
    )
    |> Stream.flat_map(fn
      {:ok, urls} -> urls
      _ -> []
    end)
  end

  def scraped_url(url) do
    case scrape(url) do
      {:ok, sub_urls_s} -> sub_urls_s
      _ -> []
    end
  end

  def scrape(url) do
    Logger.debug("Scraping: #{url}")
    with(
      {:ok, page} <- @api_client.fetch_page(url),
      {:ok, sub_urls_s} <- @scraper.uniq_urls(page)
    ) do
      {:ok, sub_urls_s}
    else
      {:error, reason} ->
        Logger.warn("Could not scrape #{url} due to #{inspect(reason)}")
        {:error, {url, reason}}
    end
  end
end
