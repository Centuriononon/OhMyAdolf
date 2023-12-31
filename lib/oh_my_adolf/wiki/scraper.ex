defmodule OhMyAdolf.Wiki.Scraper do
  @behaviour OhMyAdolf.Wiki.ScraperBehavior
  require Logger

  @fetcher Application.compile_env(
             :oh_my_adolf,
             [:wiki, :fetcher],
             OhMyAdolf.Wiki.Fetcher
           )

  @parser Application.compile_env(
              :oh_my_adolf,
              [:wiki, :parser],
              OhMyAdolf.Wiki.Parser
            )

  @impl true
  def scrape(%URI{} = url) do
    Logger.debug("Scraping: #{url}")

    with(
      {:ok, html} <- @fetcher.fetch_page(url),
      {:ok, sub_urls} <- @parser.extract_wiki_urls(html, exclude: [url])
    ) do
      {:ok, sub_urls}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end
end
