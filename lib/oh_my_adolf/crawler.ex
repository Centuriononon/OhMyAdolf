defmodule OhMyAdolf.Crawler do
  require Logger

  @scraper Application.compile_env(
             :oh_my_adolf,
             [:crawling, :scraper],
             OhMyAdolf.Wiki.Scraper
           )

  def crawl(%URI{} = url, opts \\ [chunks: 200]) do
    Stream.resource(
      get_init_handler(url, Enum.into(opts, %{})),
      &handle_next/1,
      get_finish_handler(url)
    )
  end

  defp get_init_handler(url, opts) do
    fn ->
      Logger.info("Started crawling #{url}.")

      nexts =
        url
        |> @scraper.scraped_url()
        |> Enum.map(&{url, &1})

      {nexts, [], [], opts}
    end
  end

  defp handle_next({[], [], [], _opts} = acc) do
    {:halt, acc}
  end

  defp handle_next({[], prevs, [], opts}) do
    chunks = Enum.chunk_every(prevs, opts.chunks)
    handle_next({[], [], chunks, opts})
  end

  defp handle_next({[], prevs, [chunk | chunks], opts}) do
    nexts =
      chunk
      |> Stream.map(fn {_abv_url, url} -> url end)
      |> @scraper.scraped_urls()
      |> Enum.to_list()

    handle_next({nexts, prevs, chunks, opts})
  end

  defp handle_next({[{abv, sub} = curr | nexts], prevs, chunks, opts}) do
    {[{abv, sub}], {nexts, [curr] ++ prevs, chunks, opts}}
  end

  defp get_finish_handler(url) do
    fn _acc -> Logger.info("Finished crawling #{url}.") end
  end
end
