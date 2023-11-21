defmodule OhMyAdolf.Repo do
  require Logger
  alias Bolt.Sips, as: Neo
  alias Bolt.Sips.Types.{Node, Path}

  def transaction(func) do
    Neo.transaction(Neo.conn(), func)
  end

  def get_path(
        conn \\ Neo.conn(),
        %Node{} = n1,
        %Node{} = n2,
        relationship
      )
      when is_bitstring(relationship) do
    n1_ser = serialize_node("start", n1)
    n2_ser = serialize_node("end", n2)

    conn
    |> Neo.query("""
      MATCH path = #{n1_ser}-[:#{relationship}*]->#{n2_ser}
      RETURN path
      LIMIT 1;
    """)
    |> case do
      {:ok, %{results: [%{"path" => path}]}} ->
        {:ok, extract_path_nodes(path)}

      {:ok, %{results: []}} ->
        {:error, :not_found}

      {:error, %Neo.Error{message: msg}} ->
        {:error, msg}
    end
  end

  def node_exists?(conn \\ Neo.conn(), %Node{} = n) do
    n_ser = serialize_node("node", n)

    conn
    |> Neo.query("""
      MATCH #{n_ser}
      RETURN COUNT(node) > 0 AS exists
    """)
    |> case do
      {:ok, resp} -> List.first(resp.results)["exists"]
    end
  end

  def chain_nodes(
        conn \\ Neo.conn(),
        %Node{} = n1,
        %Node{} = n2,
        relationship
      )
      when is_bitstring(relationship) do
    n1_ser = serialize_node("abv", n1)
    n2_ser = serialize_node("sub", n2)

    conn
    |> Neo.query("""
    MERGE #{n1_ser}
    MERGE #{n2_ser}
    MERGE (abv)-[:#{relationship}]->(sub);
    """)
    |> case do
      {:ok, _} -> :ok
      {:error, %Neo.Error{message: msg}} -> {:error, msg}
    end
  end

  defp extract_path_nodes(%Path{} = path) do
    path
    |> Path.graph()
    |> Enum.filter(fn
      %Node{} -> true
      _ -> false
    end)
  end

  defp serialize_node(name, %Node{} = node) do
    labels = serialize_labels(node.labels || [])
    properties = serialize_properties(node.properties || %{})

    "(#{name}#{labels}#{properties})"
  end

  defp serialize_properties(%{} = properties)
       when map_size(properties) > 0 do
    ps =
      properties
      |> Enum.map(fn
        {k, v} -> "#{k}: #{serialize_value(v)}"
      end)
      |> Enum.join(",")

    " {#{ps}}"
  end

  defp serialize_properties(%{}) do
    ""
  end

  defp serialize_value(v) when is_number(v) or is_boolean(v) do
    "#{v}"
  end

  defp serialize_value(v) do
    "'#{v}'"
  end

  defp serialize_labels([]), do: ""

  defp serialize_labels(labels) when is_list(labels) do
    ":" <> Enum.join(labels, ":")
  end
end
