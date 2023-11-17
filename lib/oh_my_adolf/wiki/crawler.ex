defmodule OhMyAdolf.Wiki.Crawler do
  @cralwer Application.compile_env(
             :oh_my_adolf,
             [:wiki, :crawler],
             OhMyAdolf.Crawler
           )
  @scraper Application.compile_env(
             :oh_my_adolf,
             [:wiki, :scraper],
             OhMyAdolf.Wiki.Scraper
           )
  @chunks Application.compile_env(:oh_my_adolf, :scraping_chunks, 200)

  def crawl(%URI{} = url) do
    @cralwer.crawl(url, &@scraper.scrape/1, chunks: @chunks, timeout: 5_000)
  end
end
