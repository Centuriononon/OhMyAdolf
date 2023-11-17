defmodule OhMyAdolf.Wiki.Pathfinder.ByCrawl do
  require Logger
  alias OhMyAdolf.Wiki.Exception.NotFoundPath
  alias OhMyAdolf.Wiki.Pathfinder.Helpers

  @repo Application.compile_env(
          :oh_my_adolf,
          [:wiki, :repo],
          OhMyAdolf.Wiki.Repo
        )
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
  @pathfinder_by_repo Application.compile_env(
    :oh_my_adolf,
    [:wiki, :repo],
    OhMyAdolf.Wiki.Pathfinder.ByRepo
  )

  def find_path(start_url, core_url) do
    @crawler.crawl(start_url)
    |> Enum.reduce_while({Graph.new(), start_url, core_url}, &handle_emit/2)
    |> case do
      {:found, path} ->
        {:ok, path}

      {:error, exception} ->
        {:error, exception}

      {%Graph{}, %URI{}, %URI{}} ->
        exc =
          NotFoundPath.new("Unavailable API source to perform the search yet")

        {:error, exc}
    end
  end

  defp handle_emit({:error, %URI{} = url, exception}, state) do
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
      Logger.debug("Found the path by reaching the core url")

      path = Helpers.get_shortest_path_from_graph(graph, start_url, core_url)
      {:ok, _resp} = @repo.register_path(path)
      {:halt, {:found, path}}
    else
      @pathfinder_by_repo.find_path_by_extention(graph, start_url, sub_url, core_url)
      |> case do
        {:ok, path} ->
          Logger.debug("Found the path by repo extension")
          {:halt, {:found, path}}

        {:error, _not_found} ->
          {:cont, {graph, start_url, core_url}}
      end
    end
  end
end
