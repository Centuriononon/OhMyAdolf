defmodule OhMyAdolf.GraphRepo do
  @moduledoc """
  This is a model over Bolt.Sips for executing queries over the URL based interface.
  """
  require Logger
  alias Bolt.Sips, as: Neo

  def transaction(func) do
    Neo.transaction(Neo.conn(), fn _conn -> func.() end)
  end

  def get_shortest_path(%URI{} = start_url, %URI{} = end_url) do
    s_str = URI.to_string(start_url)
    e_str = URI.to_string(end_url)
    s_hash = enc(s_str)
    e_hash = enc(e_str)

    Neo.conn()
    |> Neo.query("""
      MATCH
        (start:Page {url_hash: '#{s_hash}'}),
        (end:Page {url_hash: '#{e_hash}'}),
        path = shortestPath((start)-[:REFERS_TO*]-(end))
      RETURN path;
    """)
    |> case do
      {:error, %Neo.Error{message: m, code: c}} ->
        Logger.critical(
          "Could not fetch the shortest path;" <>
            " error code: #{inspect(c)}, message: #{inspect(m)}"
        )

        {:error, "not found"}

      {:ok, resp} ->
        path =
          resp
          |> extract_path()
          |> extract_nodes()
          |> page_nodes_to_urls()

        {:ok, path}
    end
  end

  defp extract_path(resp) do
    resp
    |> Map.get(:results)
    |> Enum.at(0)
    |> Map.get("path")
    |> Neo.Types.Path.graph()
  end

  defp extract_nodes(path) do
    path
    |> Stream.filter(fn
      %Neo.Types.Node{} -> true
      _ -> false
    end)
  end

  defp page_nodes_to_urls(nodes) do
    nodes
    |> Stream.map(fn node -> node.properties["url_hash"] end)
    |> Stream.map(&dec/1)
    |> Enum.map(&URI.parse/1)
  end

  def relate_pages(%URI{} = abv_url, %URI{} = sub_url) do
    a_str = URI.to_string(abv_url)
    s_str = URI.to_string(sub_url)
    a_hash = enc(a_str)
    s_hash = enc(s_str)

    Neo.conn()
    |> Neo.query("""
      MERGE (above:Page {url_hash: '#{a_hash}'})
      MERGE (sub:Page {url_hash: '#{s_hash}'})
      MERGE (above)-[:REFERS_TO]->(sub) RETURN above, sub;
    """)
    |> log_query_error()
  end

  def exists?(%URI{} = url) do
    u_str = URI.to_string(url)
    u_hash = enc(u_str)

    Neo.conn()
    |> Neo.query("""
      MATCH (p:Page {url_hash: '#{u_hash}'})
      RETURN COUNT(p) > 0 AS exists
    """)
    |> log_query_error()
    |> case do
      {:ok, resp} -> Enum.at(resp.results, 0)["exists"]
      {:error, _err} = err -> err
    end
  end

  def register_paths([[_ | _] | _] = paths) do
    query =
      paths
      |> Enum.reduce("", fn path, acc_query ->
        query =
          path
          |> Stream.map(&URI.to_string(&1))
          |> Enum.map(&enc/1)
          |> get_query_register_pages()

        acc_query <> "\n" <> query
      end)

    Neo.conn()
    |> Neo.query(query)
    |> log_query_error()
  end

  def register_path([_ | _] = path) do
    query =
      path
      |> Stream.map(&URI.to_string(&1))
      |> Enum.map(&enc/1)
      |> get_query_register_pages()

    Neo.conn()
    |> Neo.query("#{query} RETURN abv, sub")
    |> log_query_error()
  end

  defp get_query_register_pages(url_hashes) do
    """
    // Hashes
    WITH #{inspect(url_hashes)} AS url_hash_list

    // Pages
    UNWIND url_hash_list AS url_hash
    MERGE (p:Page {url_hash: url_hash})

    // Relations
    WITH url_hash_list
    UNWIND RANGE(0, SIZE(url_hash_list) - 2) AS id
    MATCH
      (abv:Page {url_hash: url_hash_list[id]}),
      (sub:Page {url_hash: url_hash_list[id + 1]})
    // Skip loop
    WHERE NOT EXISTS {
      (abv)-[:REFERS_TO]->(sub)
    }
    MERGE (abv)-[r:REFERS_TO]->(sub)
    """
  end

  defp log_query_error({:error, %Neo.Error{message: m, code: c}} = r) do
    Logger.critical(
      "Could not register path;" <>
        " error code: #{inspect(c)}, message: #{inspect(m)}"
    )

    r
  end

  defp log_query_error(r), do: r

  defp dec(url) when is_bitstring(url), do: Base.decode64!(url)
  defp enc(url) when is_bitstring(url), do: Base.encode64(url)
end
