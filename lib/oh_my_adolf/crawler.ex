defmodule OhMyAdolf.Crawler do
  require Logger

  def crawl(%URI{} = url, config) do
    Stream.resource(
      get_init_handler(url, config),
      &handle_next/1,
      get_finish_handler(url)
    )
  end

  def get_init_handler(url, config) do
    fn ->
      Logger.info("Started crawling #{url}.")

      currs =
        url
        |> scraped_url(config)
        |> Enum.map(&{url, &1})

      {currs, [], config}
    end
  end

  def handle_next({[], [], _config}) do
    {:halt, []}
  end

  def handle_next({[], prevs, config}) do
    currs =
      prevs
      |> Stream.map(fn {_abv_url, url} -> url end)
      |> scraped_urls(config)

    handle_next({currs, []})
  end

  def handle_next({[{abv_url, url} = curr | currs], prevs, config}) do
    {[{:ok, abv_url, url}], {currs, [curr] ++ prevs, config}}
  end

  def get_finish_handler(url) do
    fn _acc -> Logger.info("Finished crawling #{url}.") end
  end

  def scraped_urls(urls, config) do
    Task.Supervisor.async_stream(
      OhMyAdolf.TaskSupervisor,
      urls,
      fn url ->
        url
        |> scraped_url(config)
        |> Enum.map(fn sub_url -> {url, sub_url} end)
      end,
      # max concurency is the rate of the proxy actually
      max_concurency: Map.get(config, :max_concurency, 50),
      on_timeout: :kill_task,
      timeout: 20_000
    )
    |> Stream.flat_map(& &1)
    |> Enum.to_list()
  end

  def scraped_url(url, config) do
    case scrape(url, config) do
      {:ok, sub_urls} -> sub_urls
      _ -> []
    end
  end

  def scrape(url, config) do
    with(
      {:ok, page} <- config.api_client.fetch_page(url),
      {:ok, sub_urls} <- config.scraper.uniq_urls(page)
    ) do
      {:ok, sub_urls}
    else
      err ->
        {:error, {url, err}}
    end
  end
end
