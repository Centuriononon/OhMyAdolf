defmodule OhMyAdolf.Crawler do
  require Logger
  import OhMyAdolf.CrawlerHelpers

  @chunks Application.compile_env(:oh_my_adolf, :scraping_limit, 100)

  def crawl(%URI{} = url) do
    Stream.resource(
      get_init_handler(url),
      &handle_next/1,
      get_finish_handler(url)
    )
  end

  defp get_init_handler(url) do
    fn ->
      Logger.info("Started crawling #{url}.")

      nexts =
        url
        |> scraped_url()
        |> Stream.map(&{url, &1})
        |> Enum.to_list()

      {nexts, [], []}
    end
  end

  defp handle_next({[], [], []} = acc) do
    {:halt, acc}
  end

  defp handle_next({[], prevs, []}) do
    chunks = Enum.chunk_every(prevs, @chunks)
    handle_next({[], [], chunks})
  end

  defp handle_next({[], prevs, [chunk | chunks]}) do
    nexts =
      chunk
      |> Stream.map(fn {_abv_url, url} -> url end)
      |> scraped_urls()
      |> Enum.to_list()

    handle_next({nexts, prevs, chunks})
  end

  defp handle_next({[{abv, sub} = curr | nexts], prevs, chunks}) do
    {[{abv, sub}], {nexts, [curr] ++ prevs, chunks}}
  end

  defp get_finish_handler(url) do
    fn _acc -> Logger.info("Finished crawling of #{url}.") end
  end
end
