defmodule OhMyAdolf.Page.Wiki.Scraper do
  require Logger
  alias OhMyAdolf.Page

  @validators Application.compile_env(
               :oh_my_adolf,
               [:wiki, :page_validator],
               OhMyAdolf.Page.Wiki.Validators
             )
  @fetcher Application.compile_env(
             :oh_my_adolf,
             [:wiki, :page_fetcher],
             OhMyAdolf.Page.Wiki.Fetcher
           )

  def scrape(%Page{url: url}), do: scrape(url)

  def scrape(%URI{} = url) do
    if @validators.valid_url?(url) do
      do_scrape(url)
    else
      {:error, :invalid_url}
    end
  end

  defp do_scrape(%URI{} = url) do
    Logger.debug("Scraping: #{url}")

    with(
      {:ok, html} <- @fetcher.fetch_page(url),
      {:ok, sub_urls} <- uniq_urls(html, exclude: [url])
    ) do
      page = Page.new(url)
      sub_pages = Stream.map(sub_urls, &Page.new(&1))

      {:ok, {page, sub_pages}}
    else
      {:error, reason} ->
        Logger.warning("Could not scrape #{url} due to #{inspect(reason)}")
        {:error, reason}
    end
  end

  def uniq_urls(html, exclude: urls) when is_bitstring(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        urls =
          document
          |> Floki.find("div#bodyContent")
          |> Floki.find("a")
          |> Floki.attribute("href")
          |> Stream.map(&@validators.absolute_url/1)
          |> Stream.filter(&@validators.valid_url?/1)
          |> Stream.reject(&Enum.member?(urls, &1))
          |> Stream.uniq()

        {:ok, urls}

      _ ->
        {:error, :bad_parse}
    end
  end
end
