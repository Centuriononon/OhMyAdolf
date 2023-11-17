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
    n1_ls = serialize_labels(n2)
    n1_ps = serialize_properties(n1)

    n2_ls = serialize_labels(n2)
    n2_ps = serialize_properties(n2)

    conn
    |> Neo.query("""
      MATCH path = (s:#{n1_ls} #{n1_ps})-[:#{relationship}*]-(e:#{n2_ls} #{n2_ps})
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
    ls = serialize_labels(n)
    ps = serialize_properties(n)

    conn
    |> Neo.query("""
      MATCH (x:#{ls} #{ps})
      RETURN COUNT(x) > 0 AS exists
    """)
    |> case do
      {:ok, resp} -> {:ok, List.first(resp.results)["exists"]}
      {:error, %Neo.Error{message: msg}} -> {:error, msg}
    end
  end

  def register_relation(
        conn \\ Neo.conn(),
        %Node{} = n1,
        %Node{} = n2,
        relationship
      )
      when is_bitstring(relationship) do
    n1_ls = serialize_labels(n2)
    n1_ps = serialize_properties(n1)

    n2_ls = serialize_labels(n2)
    n2_ps = serialize_properties(n2)

    conn
    |> Neo.query("""
    MERGE (a:#{n1_ls} #{n1_ps})
    MERGE (b:#{n2_ls} #{n2_ps})
    MERGE (a)-[:#{relationship}]->(b);
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

  defp serialize_properties(%Node{} = n) do
    ps =
      n.properties
      |> Enum.map(fn {k, v} -> "#{k}: '#{v}'" end)
      |> Enum.join(",")

    "{#{ps}}"
  end

  defp serialize_labels(%Node{} = n) do
    Enum.join(n.labels, ":")
  end
end
