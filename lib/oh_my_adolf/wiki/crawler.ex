defmodule OhMyAdolf.Wiki.Crawler do
  require Logger

  @scraper Application.compile_env(
             :oh_my_adolf,
             [:wiki, :scraper],
             OhMyAdolf.Wiki.Scraper
           )
  @chunks Application.compile_env(:oh_my_adolf, [:wiki, :scraping_chunks], 200)
  @timeout Application.compile_env(
             :oh_my_adolf,
             [:wiki, :scraping_timeout],
             6000
           )

  def crawl(%URI{} = start_url) do
    Stream.resource(
      get_init_handler(start_url),
      &handle_next/1,
      get_finish_handler(start_url)
    )
  end

  defp get_init_handler(start_url) do
    fn ->
      Logger.info("Started crawling #{inspect(start_url)}")

      nexts = List.flatten([scrape(start_url)])
      {nexts, []}
    end
  end

  defp handle_next({[], []} = acc) do
    # there is nothing to process, then halt
    {:halt, acc}
  end

  defp handle_next({[], queue}) do
    chunk = Enum.take(queue, @chunks)
    queue = Enum.drop(queue, @chunks)

    # scraping the next chunk of urls
    nexts = scrape_many(chunk)
    handle_next({nexts, queue})
  end

  defp handle_next({[{:ok, abv, sub} | nexts], queue}) do
    # emit and put the sub url for further scraping
    {[{:ok, abv, sub}], {nexts, [sub | queue]}}
  end

  defp handle_next({[{:error, reason, url} | nexts], queue}) do
    # just emit errored scrape
    {[{:error, reason, url}], {nexts, queue}}
  end

  defp get_finish_handler(start_url) do
    fn _acc -> Logger.info("Finished crawling #{inspect(start_url)}") end
  end

  defp scrape_many(urls) do
    Task.Supervisor.async_stream(
      OhMyAdolf.TaskSupervisor,
      urls,
      &do_scrape/1,
      max_concurency: @chunks,
      timeout: @timeout,
      on_timeout: :kill
    )
    |> Enum.flat_map(fn
      {:ok, reply} -> List.flatten([reply])
      _ -> []
    end)
  end

  defp scrape(url) do
    try do
      Task.async(fn -> do_scrape(url) end)
      |> Task.await(@timeout)
    catch
      :exit, _ -> {:error, :timeout, url}
    end
  end

  defp do_scrape(url) do
    case @scraper.scrape(url) do
      {:ok, sub_urls} ->
        Enum.map(sub_urls, &{:ok, url, &1})

      {:error, reason} ->
        {:error, reason, url}
    end
  end
end
