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
      Qex.new([scrape_lazy_re(url, config)])
    end
  end

  def handle_next(scrapers_q) do
    case Qex.pop(scrapers_q) do
      {{:value, scraper}, next_scrapers_q} ->
        case scraper.() do
          {:ok, {fst_url, sub_scrapers_q}} ->
            {[{:ok, fst_url}], Qex.join(next_scrapers_q, sub_scrapers_q)}

          {:ok, {abv_url, cur_url, sub_scrapers_q}} ->
            {[{:ok, abv_url, cur_url}], Qex.join(next_scrapers_q, sub_scrapers_q)}

          {:error, {url, err}} ->
            {[{:error, {url, err}}], scrapers_q}
        end

      {:empty, _scrapers_q} ->
        {:halt, []}
    end
  end

  def get_finish_handler(url) do
    fn _acc -> Logger.info("Finished crawling #{url}.") end
  end

  def scrape_many_lazy_re(%Qex{} = urls_q, %URI{} = abv_url, config) do
    urls_q
    |> Enum.map(fn url ->
      fn ->
        with {:ok, {sub_url, sub_scrapers_q}} <- scrape_lazy_re(url, config).() do
          {:ok, {abv_url, sub_url, sub_scrapers_q}}
        end
      end
    end)
    |> Qex.new()
  end

  def scrape_lazy_re(url, config) do
    fn ->
      with {:ok, sub_urls_q} <- scrape(url, config) do
        sub_scrapers_q = scrape_many_lazy_re(sub_urls_q, url, config)

        {:ok, {url, sub_scrapers_q}}
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
      {:ok, Qex.new(sub_urls)}
    end
  end
end
