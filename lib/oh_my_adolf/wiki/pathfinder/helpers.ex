defmodule OhMyAdolf.Wiki.Pathfinder.Helpers do
  require Logger
  alias OhMyAdolf.Wiki.WikiURL

  @repo Application.compile_env(
          :oh_my_adolf,
          [:wiki, :page_repo],
          OhMyAdolf.Wiki.Repo
        )

  def add_relation_to_graph(
        graph,
        %WikiURL{} = abv_url,
        %WikiURL{} = sub_url
      ) do
    abv_ref = WikiURL.to_string(abv_url)
    sub_ref = WikiURL.to_string(sub_url)

    # registering vertices with WikiURL labels
    graph
    |> Graph.add_vertex(abv_ref, abv_url)
    |> Graph.add_vertex(sub_ref, sub_url)
    |> Graph.add_edge(abv_ref, sub_ref)
  end

  def get_shortest_path_from_graph(
        graph,
        %WikiURL{} = start_url,
        %WikiURL{} = end_url
      ) do
    start_ref = WikiURL.to_string(start_url)
    end_ref = WikiURL.to_string(end_url)

    graph
    |> Graph.get_shortest_path(start_ref, end_ref)
    |> Enum.map(&extract_label(graph, &1))
  end

  defp extract_label(graph, ref) do
    graph
    |> Graph.vertex_labels(ref)
    |> List.first()
  end

  def get_path_by_repo_extension(
        graph,
        %WikiURL{} = start_url,
        %WikiURL{} = sub_url,
        %WikiURL{} = core_url
      ) do
    # initial check to avoid transaction overhead
    if @repo.exists?(sub_url) do
      do_get_path_by_repo_extension(graph, start_url, sub_url, core_url)
    else
      {:error, :not_found}
    end
  end

  defp do_get_path_by_repo_extension(graph, start_url, sub_url, core_url) do
    # Taking the accumulated heading path
    heading_path =
      Task.async(fn ->
        get_shortest_path_from_graph(graph, start_url, sub_url)
      end)
      |> Task.await(10_000)

    @repo.transaction(fn conn ->
      Logger.debug("Opened transaction to get path by repo extension")

      # if current url is registered already
      if @repo.exists?(conn, sub_url) do
        Logger.debug("Found the current url registered in the repo")

        # then get the path from the current url to the core one
        case @repo.get_shortest_path(conn, sub_url, core_url) do
          {:ok, [_sub_page | tailing_path]} ->
            Logger.debug("Found the tailing path from the url")

            # merging the paths
            final_path = Enum.concat(heading_path, tailing_path)

            # register the final paths
            @repo.register_path(conn, final_path)

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
