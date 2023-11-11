defmodule OhMyAdolf.Pathfinder do
  require Logger

  @scout Application.compile_env(:oh_my_adolf, :scout, OhMyAdolf.Scout)
  @crawler Application.compile_env(:oh_my_adolf, :crawler, OhMyAdolf.Crawler)

  def find_path(start_url, core_url) do
    @crawler.crawl(start_url)
    |> Enum.reduce_while(Graph.new(), process_stream(start_url, core_url))
    |> case do
      {:found, path} ->
        {:ok, path}

      _ ->
        Logger.error("Could not find the path for #{start_url}")

        {:error, "could not find the path yet"}
    end
  end

  defp process_stream(start_url, core_url) do
    fn {abv_url, url}, graph ->
      Logger.debug("Processing relation: #{abv_url} --> #{url}")

      updated_graph = Graph.add_edge(graph, Graph.Edge.new(abv_url, url))
      passed_path = Graph.get_shortest_path(updated_graph, start_url, url)

      case @scout.designate_final_path(passed_path, core_url) do
        {:ok, path} ->
          {:halt, {:found, path}}

        _ ->
          {:cont, updated_graph}
      end
    end
  end
end
