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

      currs =
        url
        |> scraped_url(config)
        |> Enum.map(&{url, &1})

      {currs, [], config}
    end
  end

  defp handle_next({[], [], _config}) do
    {:halt, []}
  end

  defp handle_next({[], prevs, config}) do
    currs =
      prevs
      |> Stream.map(fn {_abv_url, url} -> url end)
      |> scraped_urls(config)

    handle_next({currs, [], config})
  end

  defp handle_next({[{abv_url, url} = curr | currs], prevs, config}) do
    {[{abv_url, url}], {currs, [curr] ++ prevs, config}}
  end

  defp get_finish_handler(url) do
    fn _acc -> Logger.info("Finished crawling of #{url}.") end
  end
end
