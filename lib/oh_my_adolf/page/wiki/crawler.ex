defmodule OhMyAdolf.Page.Wiki.Crawler do
  alias OhMyAdolf.Page

  @cralwer Application.compile_env(
             :oh_my_adolf,
             [:wiki, :page_crawler],
             OhMyAdolf.Page.Crawler
           )
  @scraper Application.compile_env(
             :oh_my_adolf,
             [:wiki, :page_scraper],
             OhMyAdolf.Page.Wiki.Scraper
           )
  @chunks Application.compile_env(:oh_my_adolf, :scraping_chunks, 200)

  def crawl(%Page{url: url}), do: crawl(url)

  def crawl(%URI{} = url) do
    @cralwer.crawl(url, &@scraper.scrape/1, chunks: @chunks, timeout: 5_000)
  end
end
