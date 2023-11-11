defmodule OhMyAdolf.Pathfinder do
  require Logger

  @scout Application.compile_env(:oh_my_adolf, :scout, OhMyAdolf.Scout)
  @crawler Application.compile_env(:oh_my_adolf, :crawler, OhMyAdolf.Crawler)

  def find_path(start_url, core_url) do
    @crawler.crawl(start_url)
    |> Enum.reduce_while(
      Graph.new(),
      fn {abv_url, url}, graph ->
        Logger.debug("Processing relation: #{abv_url} --> #{url}")

        updated_graph = Graph.add_edge(graph, Graph.Edge.new(abv_url, url))
        passed_path = Graph.get_shortest_path(updated_graph, start_url, url)

        if match_urls(url, core_url) do
          {:halt, {:found, passed_path}}
        else
          @scout.designate_final_path(passed_path, core_url)
          |> case do
            {:ok, final_path} -> {:halt, {:found, final_path}}
            {:error, _msg} -> {:cont, updated_graph}
          end
        end
      end
    )
    |> case do
      {:found, path} -> {:ok, path}
      _ -> {:error, "could not find the path yet"}
    end
  end

  defp match_urls(url_a, url_b), do: to_string(url_a) === to_string(url_b)
end
