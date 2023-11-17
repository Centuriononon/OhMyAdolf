defmodule OhMyAdolf.Wiki.Pathfinder.Helpers do
  def add_relation_to_graph(
        graph,
        %URI{} = abv_url,
        %URI{} = sub_url
      ) do
    abv_ref = URI.to_string(abv_url)
    sub_ref = URI.to_string(sub_url)

    graph
    |> Graph.add_vertex(abv_ref, abv_url)
    |> Graph.add_vertex(sub_ref, sub_url)
    |> Graph.add_edge(abv_ref, sub_ref)
  end

  def get_path_from_graph(
        graph,
        %URI{} = start_url,
        %URI{} = end_url
      ) do
    start_ref = URI.to_string(start_url)
    end_ref = URI.to_string(end_url)

    graph
    |> Graph.get_shortest_path(start_ref, end_ref)
    |> Enum.map(&extract_label(graph, &1))
  end

  defp extract_label(graph, ref) do
    graph
    |> Graph.vertex_labels(ref)
    |> List.first()
  end
end
