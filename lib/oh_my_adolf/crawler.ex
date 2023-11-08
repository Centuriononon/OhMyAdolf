defmodule OhMyAdolf.Crawler do
  require Logger

  def crawl_urls(%URI{} = url, config) do
    Logger.info("Started streaming for #{url}")

    Stream.resource(
      fn -> {config, :state} end,
      &emit/1,
      fn _ -> log_finish(url) end
    )
  end

  defp emit({config, :state}) do
    Process.sleep(10000)
    {URI.new(""), {config, :state}}
  end

  defp log_finish(url) do
    Logger.info("Finished streaming for #{url}")
  end

  # defp scrape(url, config) do
  #   with(
  #     {:ok, page} <- config.client.fetch_page(url),
  #     {:ok, urls} <- config.scraper.uniq_urls(page)
  #   ) do
  #     urls
  #   end
  # end
end
