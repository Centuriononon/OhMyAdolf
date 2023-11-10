defmodule OhMyAdolf.Crawler do
  require Logger
  import OhMyAdolf.CrawlerHelpers

  def crawl(%URI{} = url, config) do
    config = validate_config!(config)

    Stream.resource(
      get_init_handler(url, config),
      &handle_next/1,
      get_finish_handler(url)
    )
  end

  defp get_init_handler(url, config) do
    fn ->
      Logger.info("Started crawling #{url}.")

      nexts =
        url
        |> scraped_url(config)
        |> Enum.map(&{url, &1})

      {nexts, [], [], config}
    end
  end

  defp handle_next({[], [], [], _config} = acc) do
    {:halt, acc}
  end

  defp handle_next({[], prevs, [], config}) do
    chunks = Enum.chunk_every(prevs, 200)
    handle_next({[], [], chunks, config})
  end

  defp handle_next({[], [], [chunk | chunks], config}) do
    nexts =
      chunk
      |> Stream.map(fn {_abv_url, url} -> url end)
      |> scraped_urls(config)
      |> Enum.to_list()

    handle_next({nexts, [], chunks, config})
  end

  defp handle_next({[curr | nexts], prevs, chunks, config}) do
    {[curr], {nexts, [curr] ++ prevs, chunks, config}}
  end

  defp get_finish_handler(url) do
    fn _acc -> Logger.info("Finished crawling of #{url}.") end
  end
end
