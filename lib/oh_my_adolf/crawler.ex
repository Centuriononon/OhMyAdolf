defmodule OhMyAdolf.Crawler do
  require Logger

  def crawl(start_point, scrape_func, opts) do
    default_opts = %{chunks: 150, timeout: 5000, scrape_func: scrape_func}

    Stream.resource(
      get_init_handler(start_point, Enum.into(opts, default_opts)),
      &handle_next/1,
      get_finish_handler(start_point)
    )
  end

  defp get_init_handler(start_point, opts) do
    fn ->
      Logger.info("Started crawling #{inspect(start_point)}")
      nexts = List.flatten([scrape(start_point, opts)])
      {nexts, [], opts}
    end
  end

  defp handle_next({[], [], _opts} = acc) do
    # there is nothing to process, then halt
    {:halt, acc}
  end

  defp handle_next({[], queue, opts}) do
    chunk = Enum.take(queue, opts.chunks)
    queue = Enum.drop(queue, opts.chunks)

    # scraping the next chunk of points
    nexts = scrape_many(chunk, opts)
    handle_next({nexts, queue, opts})
  end

  defp handle_next({[{:ok, abv, sub} | nexts], queue, opts}) do
    # emit and put the sub point for further scraping
    {[{:ok, abv, sub}], {nexts, [sub | queue], opts}}
  end

  defp handle_next({[{:error, point, reason} | nexts], queue, opts}) do
    # just emit errored scrape
    {[{:error, point, reason}], {nexts, queue, opts}}
  end

  defp get_finish_handler(start_point) do
    fn _acc -> Logger.info("Finished crawling #{inspect(start_point)}.") end
  end

  defp scrape_many(points, opts) do
    %{chunks: chunks, timeout: timeout} = opts

    Task.Supervisor.async_stream(
      OhMyAdolf.TaskSupervisor,
      points,
      &scrape(&1, opts),
      max_concurency: chunks,
      on_timeout: :kill_task,
      timeout: timeout
    )
    |> Enum.flat_map(fn
      {:ok, reply} -> List.flatten([reply])
      _ -> []
    end)
  end

  defp scrape(point, %{scrape_func: scrape_func}) do
    case scrape_func.(point) do
      {:ok, {point, sub_points}} ->
        Enum.map(sub_points, &{:ok, point, &1})

      {:error, reason} ->
        {:error, point, reason}
    end
  end
end
