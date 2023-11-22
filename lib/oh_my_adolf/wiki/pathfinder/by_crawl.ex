defmodule OhMyAdolf.Wiki.Pathfinder.ByCrawl do
  require Logger
  alias OhMyAdolf.Wiki.NotFoundPathError
  alias OhMyAdolf.Wiki.Pathfinder.Helpers

  @crawler Application.compile_env(
             :oh_my_adolf,
             [:wiki, :crawler],
             OhMyAdolf.Wiki.Crawler
           )
  @wiki_url Application.compile_env(
              :oh_my_adolf,
              [:wiki, :wiki_url],
              OhMyAdolf.Wiki.WikiURL
            )
  @paths Application.compile_env(
           :oh_my_adolf,
           [:wiki, :paths],
           OhMyAdolf.Wiki.Paths
         )

  def find_path(start_url, core_url) do
    @crawler.crawl(start_url)
    |> Enum.reduce_while({Graph.new(), start_url, core_url}, &handle_emit/2)
    |> case do
      {:found, path} ->
        {:ok, path}

      {%Graph{}, %URI{}, %URI{}} ->
        exc =
          NotFoundPathError.exception(
            "Unavailable API source to perform the search yet"
          )

        {:error, exc}
    end
  end

  defp handle_emit({:error, exception, %URI{} = url}, state) do
    Logger.error("Could not scrape #{url} due to #{inspect(exception)}")
    {:cont, state}
  end

  defp handle_emit(
         {:ok, %URI{} = abv_url, %URI{} = sub_url},
         {graph, start_url, core_url}
       ) do
    Logger.debug("Processing relation: #{abv_url} --> #{sub_url}")

    graph = Helpers.add_relation_to_graph(graph, abv_url, sub_url)

    if @wiki_url.canonical?(sub_url, core_url) do
      path = get_path(graph, start_url, sub_url)
      :ok = @paths.register_path(path)

      {:halt, {:found, path}}
    else
      try_extend_path(graph, sub_url, start_url, core_url)
    end
  end

  defp try_extend_path(graph, sub_url, start_url, core_url) do
    with(
      true <- @paths.registered_url?(sub_url),
      path <- get_path(graph, start_url, sub_url),
      {:ok, final_path} <- @paths.extend_path(path, core_url)
    ) do
      Logger.debug("Found the path by repo extention")
      {:halt, {:found, final_path}}
    else
      _ ->
        {:cont, {graph, start_url, core_url}}
    end
  end

  defp get_path(graph, start_url, sub_url) do
    Task.async(fn ->
      Helpers.find_path_from_graph(graph, start_url, sub_url)
    end)
    |> Task.await(10_000)
  end
end
