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
      [scrape_lazy_re(url, config)]
    end
  end

  def handle_next([scraper | scrapers]) do
    case scraper.() do
      {:ok, {fst_url, sub_scraper}} ->
        {[{:ok, fst_url}], scrapers ++ sub_scraper}

      {:ok, {abv_url, cur_url, sub_scraper}} ->
        {[{:ok, abv_url, cur_url}], scrapers ++ sub_scraper}

      {:error, {url, err}} ->
        {[{:error, {url, err}}], scrapers}
    end
  end

  def handle_next([]) do
    {:halt, []}
  end

  def get_finish_handler(url) do
    fn _acc -> Logger.info("Finished crawling #{url}.") end
  end

  def scrape_many_lazy_re(urls, abv_url, config) do
    Enum.map(urls, fn url ->
      fn ->
        with {:ok, {sub_url, sub_scrapers}} <- scrape_lazy_re(url, config).() do
          {:ok, {abv_url, sub_url, sub_scrapers}}
        end
      end
    end)
  end

  def scrape_lazy_re(url, config) do
    fn ->
      with {:ok, sub_urls} <- scrape(url, config) do
        sub_scrapers = scrape_many_lazy_re(sub_urls, url, config)

        {:ok, {url, sub_scrapers}}
      else
        err ->
          {:error, {url, err}}
      end
    end
  end

  def scrape(url, config) do
    with(
      {:ok, page} <- config.api_client.fetch_page(url),
      {:ok, sub_urls} <- config.scraper.uniq_urls(page)
    ) do
      {:ok, sub_urls}
    end
  end
end
