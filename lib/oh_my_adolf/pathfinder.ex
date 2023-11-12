defmodule OhMyAdolf.Pathfinder do
  require Logger

  @graph_repo Application.compile_env(
                :oh_my_adolf,
                :graph_repo,
                OhMyAdolf.GraphRepo
              )
  @crawler Application.compile_env(:oh_my_adolf, :crawler, OhMyAdolf.Crawler)

  def find_path(start_url, core_url) do
    @crawler.crawl(start_url)
    |> Enum.reduce_while(Graph.new(), process_stream(start_url, core_url))
    |> case do
      {:found, path} ->
        {:ok, path}

      _ ->
        Logger.error("Could not find the path for #{start_url}")
        {:error, "not found"}
    end
  end

  defp process_stream(start_url, core_url) do
    fn {abv_url, url}, graph ->
      Logger.debug("Processing relation: #{abv_url} --> #{url}")
      updated_graph = Graph.add_edge(graph, Graph.Edge.new(abv_url, url))

      updated_graph
      |> find_final_path(start_url, url, core_url)
      |> case do
        {:ok, path} ->
          Logger.debug("Found url during relation process")
          {:halt, {:found, path}}

        _ ->
          Logger.debug("Not found url dudring relation process")
          {:cont, updated_graph}
      end
    end
  end

  defp find_final_path(graph, start_url, url, core_url) do
    @graph_repo.transaction(fn ->
      if @graph_repo.exists?(url) do
        paths = Graph.get_paths(graph, start_url, url)
        {:ok, _resp} = @graph_repo.register_paths(paths)
        {:ok, _path} = get_shortest_path(start_url, core_url)
      else
        {:error, "not found"}
      end
    end)
    |> case do
      {:ok, res} -> res
      {:error, err} -> {:error, err}
    end
  end

  def get_shortest_path(%URI{} = url, %URI{} = end_url) do
    if to_string(url) == to_string(end_url) do
      {:ok, [url]}
    else
      @graph_repo.get_shortest_path(url, end_url)
    end
  end
end
