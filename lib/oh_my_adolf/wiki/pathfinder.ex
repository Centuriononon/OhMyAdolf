defmodule OhMyAdolf.Wiki.Pathfinder do
  require Logger
  alias OhMyAdolf.Wiki.WikiURL
  alias OhMyAdolf.Wiki.Pathfinder.Helpers
  alias OhMyAdolf.Wiki.Exception.NotFoundPath

  @crawler Application.compile_env(
             :oh_my_adolf,
             [:wiki, :crawler],
             OhMyAdolf.Wiki.Crawler
           )
  @repo Application.compile_env(
          :oh_my_adolf,
          [:wiki, :repo],
          OhMyAdolf.Wiki.Repo
        )

  def find_path(%WikiURL{} = start_url, %WikiURL{} = core_url) do
    if WikiURL.canonical?(start_url, core_url) do
      {:ok, [core_url]}
    else
      with {:error, _} <- @repo.get_shortest_path(start_url, core_url) do
        find_by_crawl(start_url, core_url)
      end
    end
  end

  defp find_by_crawl(start_url, core_url) do
    @crawler.crawl(start_url)
    |> Enum.reduce_while({Graph.new(), start_url, core_url}, &handle_emit/2)
    |> case do
      {:found, path} ->
        {:ok, path}

      {:error, exception} ->
        {:error, exception}

      _ ->
        {:error,
         NotFoundPath.new(
           "Could not find the requested path due" <>
             " to external problems or internal failure"
         )}
    end
  end

  defp handle_emit({:error, %WikiURL{} = url, exception}, state) do
    Logger.error("Could not scrape #{url} due to #{inspect(exception)}")
    {:cont, state}
  end

  defp handle_emit(
         {:ok, %WikiURL{} = abv_url, %WikiURL{} = sub_url},
         {graph, start_url, core_url}
       ) do
    Logger.debug("Processing relation: #{abv_url} --> #{sub_url}")

    graph = Helpers.add_relation_to_graph(graph, abv_url, sub_url)

    if WikiURL.canonical?(sub_url, core_url) do
      get_path_from_graph(graph, start_url, core_url)
    else
      try_get_path_form_repo(graph, start_url, sub_url, core_url)
    end
  end

  defp try_get_path_form_repo(graph, start_url, sub_url, core_url) do
    Helpers.get_path_by_repo_extension(graph, start_url, sub_url, core_url)
    |> case do
      {:ok, path} ->
        Logger.debug("Found the path by repo extension")
        {:halt, {:found, path}}

      {:error, _not_found} ->
        {:cont, {graph, start_url, core_url}}
    end
  end

  defp get_path_from_graph(graph, start_url, core_url) do
    Logger.debug("Found the path by reaching the core url")

    path = Helpers.get_shortest_path_from_graph(graph, start_url, core_url)
    {:ok, _resp} = @repo.register_path(path)
    {:halt, {:found, path}}
  end
end
