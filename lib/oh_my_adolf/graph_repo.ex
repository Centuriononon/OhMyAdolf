defmodule OhMyAdolf.GraphRepo do
  @moduledoc """
  This is a model over Bolt.Sips for executing queries over the URL based interface.
  """
  require Logger
  alias Bolt.Sips, as: Neo

  # def transaction(func), do: Neo.transaction(Neo.conn(), func)
  def transaction(func), do: func.()

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
        Logger.info(
          "Fetched the shortest path;" <>
            " records info: #{inspect(resp.records)}"
        )

        path =
          resp
          |> Map.get(:results)
          |> Enum.at(0)
          |> Map.get("path")
          |> Neo.Types.Path.graph()
          |> Stream.filter(fn
            %Neo.Types.Node{} -> true
            _ -> false
          end)
          |> Stream.map(fn node -> node.properties["url_hash"] end)
          |> Stream.map(&dec/1)
          |> Enum.map(&URI.parse/1)

        {:ok, path}
    end
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
    |> case do
      {:error, %Neo.Error{message: m, code: c}} ->
        Logger.critical(
          "Could not relate pages;" <>
            " error code: #{inspect(c)}, message: #{inspect(m)}"
        )

        {:error, "query error"}

      {:ok, resp} ->
        Logger.info("Related pages; records info: #{inspect(resp.records)}")

        {:ok}
    end
  end

  def exists?(%URI{} = url) do
    u_str = URI.to_string(url)
    u_hash = enc(u_str)

    Neo.conn()
    |> Neo.query("""
      MATCH (p:Page {url_hash: '#{u_hash}'})
      RETURN COUNT(p) > 0 AS exists
    """)
    |> case do
      {:error, %Neo.Error{message: m, code: c}} ->
        Logger.critical(
          "Could check page for existence;" <>
            " error code: #{inspect(c)}, message: #{inspect(m)}"
        )

        {:error, "query error"}

      {:ok, resp} ->
        Enum.at(resp.results, 0)["exists"]
    end
  end

  def register_path([_ | _] = path) do
    url_hashes =
      path
      |> Stream.map(&URI.to_string(&1))
      |> Enum.map(fn u -> "{url_hash: '#{u}'}" end)

    Neo.conn()
    |> Neo.query("""
      // Hashes
      WITH #{inspect(url_hashes)} AS url_hash_list

      // Pages
      UNWIND url_hash_list AS url_hash
      MERGE (p:Page {url_hash: url_hash})

      // Relations
      WITH url_hash_list
      UNWIND RANGE(0, SIZE(url_hash_list) - 2) AS id
      MATCH (abv:Page {url_hash: url_hash_list[id]})
      MATCH (sub:Page {url_hash: url_hash_list[id + 1]})
      MERGE (abv)-[:LINKED_TO]->(sub)
    """)
  end

  defp dec(url) when is_bitstring(url), do: Base.decode64!(url)
  defp enc(url) when is_bitstring(url), do: Base.encode64(url)
end
