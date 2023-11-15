defmodule OhMyAdolf.Page.Wiki.Pathfinder do
  require Logger
  alias OhMyAdolf.Page
  alias OhMyAdolf.Page.Wiki.Pathfinder.Helpers

  @crawler Application.compile_env(
             :oh_my_adolf,
             [:wiki, :page_crawler],
             OhMyAdolf.Page.Wiki.Crawler
           )
  @repo Application.compile_env(
          :oh_my_adolf,
          [:wiki, :page_repo],
          OhMyAdolf.Page.Repo
        )

  def find_path(%URI{} = start_url, %URI{} = core_url) do
    start_url = Page.standard_url(start_url)
    core_url = Page.standard_url(core_url)

    @repo.get_shortest_path(start_url, core_url)
    |> case do
      {:error, _not_found} ->
        with {:ok, path} <- find_by_crawl(start_url, core_url) do
          Logger.debug("Found new path by crawling")
          {:ok, path}
        end

      {:ok, path} ->
        Logger.debug("Found the path registered in the repo")
        {:ok, path}
    end
  end

  defp find_by_crawl(start_url, core_url) do
    @crawler.crawl(start_url)
    |> Enum.reduce_while({Graph.new(), start_url, core_url}, &handle_emit/2)
    |> case do
      {:found, path} -> {:ok, path}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :not_found}
    end
  end

  defp handle_emit({:error, %URI{} = url, reason}, _) do
    Logger.error("Could start crawling #{url} due to #{inspect(reason)}")
    {:halt, {:error, reason}}
  end

  defp handle_emit({:error, %Page{} = page, reason}, state) do
    Logger.error("Could not scrape #{page.url} due to #{inspect(reason)}")
    {:cont, state}
  end

  defp handle_emit(
         {:ok, %Page{url: abv_url} = abv, %Page{url: sub_url} = sub},
         {graph, start_url, core_url}
       ) do
    # Initiate subgraph every 10k vertexes..?
    Logger.debug("Processing relation: #{abv_url} --> #{sub_url}")

    graph = Helpers.add_relation_to_graph(graph, abv, sub)

    if Page.canonical?(sub_url, core_url) do
      Logger.debug(
        "Found the path by reaching the core url. " <>
          "Collecting the accumulated paths..."
      )

      [path | _] =
        paths = Helpers.get_paths_from_graph(graph, start_url, core_url)

      {:ok, _resp} = @repo.register_paths(paths)

      {:halt, {:found, path}}
    else
      Helpers.get_path_by_repo_extension(graph, start_url, sub_url, core_url)
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
