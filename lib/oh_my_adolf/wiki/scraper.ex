defmodule OhMyAdolf.Wiki.Scraper do
  @moduledoc """
  Parses and scrapes wiki pages.
  """
  require Logger

  @api_client Application.compile_env(
                :oh_my_adolf,
                :api_client,
                OhMyAdolf.Wiki.APIClient
              )

  @timeout Application.compile_env(
             :oh_my_adolf,
             :scraping_timeout,
             5_000
           )
  @chunks Application.compile_env(
            :oh_my_adolf,
            :max_concurent_scrapers,
            100
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

  def scrape(%URI{} = url) do
    Logger.debug("Scraping: #{url}")
    with(
      {:ok, page} <- @api_client.fetch_page(url),
      {:ok, sub_urls_stream} <- uniq_urls(page, exclude: [url])
    ) do
      {:ok, sub_urls_stream}
    else
      {:error, reason} ->
        Logger.warn("Could not scrape #{url} due to #{inspect(reason)}")
        {:error, {url, reason}}
    end
  end

  def uniq_urls(page, exclude: urls) when is_bitstring(page) do
    case Floki.parse_document(page) do
      {:ok, document} ->
        urls =
          document
          |> Floki.find("div#bodyContent")
          |> Floki.find("a")
          |> Floki.attribute("href")
          |> Stream.map(&@api_client.absolute_path/1)
          |> Stream.filter(&@api_client.api_url?/1)
          |> Stream.reject(&Enum.member?(urls, &1))
          |> Stream.uniq()

        {:ok, urls}

      _ ->
        {:error, :bad_parse}
    end
  end
end
