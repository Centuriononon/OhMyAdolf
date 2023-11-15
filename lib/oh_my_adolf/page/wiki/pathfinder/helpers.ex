defmodule OhMyAdolf.Page.Wiki.Pathfinder.Helpers do
  require Logger
  alias OhMyAdolf.Page

  @repo Application.compile_env(
          :oh_my_adolf,
          [:wiki, :page_repo],
          OhMyAdolf.Page.Repo
        )

  def add_relation_to_graph(graph, %Page{} = abv, %Page{} = sub) do
    abv_ref = URI.to_string(abv.url)
    sub_ref = URI.to_string(sub.url)

    graph
    |> Graph.add_vertex(abv_ref, abv)
    |> Graph.add_vertex(sub_ref, sub)
    |> Graph.add_edge(abv_ref, sub_ref)
  end

  def get_paths_from_graph(graph, %URI{} = start_url, %URI{} = end_url) do
    start_ref = URI.to_string(start_url)
    end_ref = URI.to_string(end_url)

    graph
    |> Graph.get_paths(start_ref, end_ref)
    |> Enum.map(&refs_to_pages(graph, &1))
  end

  defp refs_to_pages(graph, refs) do
    Enum.map(refs, &ref_to_page(graph, &1))
  end

  defp ref_to_page(graph, ref) do
    graph
    |> Graph.vertex_labels(ref)
    |> List.first()
  end

  def get_path_by_repo_extension(graph, start_url, sub_url, core_url) do
    # initial check to remove transaction overhead
    if @repo.exists?(sub_url) do
      do_get_path_by_repo_extension(graph, start_url, sub_url, core_url)
    else
      {:error, :not_found}
    end
  end

  defp do_get_path_by_repo_extension(graph, start_url, sub_url, core_url) do
    @repo.transaction(fn conn ->
      Logger.debug("Opened transaction to get path by repo extension")

      # if current url is registered already
      if @repo.exists?(conn, sub_url) do
        Logger.debug("Found the current url registered in the repo")

        # then get the path from the current url to the core one
        case @repo.get_shortest_path(conn, sub_url, core_url) do
          {:ok, tailing_path} ->
            Logger.debug("Found the tailing path from the url")

            # merge the found tailing path with the accumulated heading paths
            heading_paths = get_paths_from_graph(graph, start_url, sub_url)

            [final_path | _] =
              final_paths =
              Enum.map(heading_paths, &Enum.concat(&1, tailing_path))

            # register the final paths
            @repo.register_paths(conn, final_paths)

            {:ok, final_path}

          {:error, _not_found} ->
            Logger.error("Not found the tailing path from the url")
            {:error, :not_found}
        end
      else
        Logger.error("Not found the current url during transaction")
        {:error, :not_found}
      end
    end)
    |> case do
      {:ok, reply} ->
        reply

      {:error, reason} ->
        Logger.critical("Could not perform transaction due to #{reason}")
        {:error, :not_found}
    end
  end
end
