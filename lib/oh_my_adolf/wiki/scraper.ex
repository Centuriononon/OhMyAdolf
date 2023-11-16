defmodule OhMyAdolf.Wiki.Scraper do
  require Logger
  alias OhMyAdolf.Wiki.WikiURL
  alias OhMyAdolf.Wiki.Exception.{FailedParse}

  @fetcher Application.compile_env(
             :oh_my_adolf,
             [:wiki, :fetcher],
             OhMyAdolf.Wiki.Fetcher
           )

  def scrape(%URI{} = uri) do
    with {:ok, url} <- WikiURL.new(uri) do
      scrape(url)
    end
  end

  def scrape(%WikiURL{} = url) do
    Logger.debug("Scraping: #{url}")

    with(
      {:ok, html} <- @fetcher.fetch_page(url),
      {:ok, sub_urls} <- uniq_wiki_urls(html, exclude: [url])
    ) do
      {:ok, {url, sub_urls}}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp uniq_wiki_urls(html, exclude: urls) when is_bitstring(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        urls =
          document
          |> Floki.find("div#bodyContent")
          |> Floki.find("a")
          |> Floki.attribute("href")
          |> Stream.map(&WikiURL.absolute_url/1)
          |> Stream.filter(&WikiURL.valid_url?/1)
          |> Stream.map(&WikiURL.new!/1)
          |> Stream.reject(&Enum.member?(urls, &1))

        {:ok, urls}

      _ ->
        exc = FailedParse.new("Could not parse document")
        {:error, exc}
    end
  end
end
