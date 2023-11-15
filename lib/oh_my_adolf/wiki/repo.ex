defmodule OhMyAdolf.Wiki.Repo do
  @moduledoc """
  This is a model over Bolt.Sips for executing queries over the Wiki based interface.
  """
  require Logger
  alias Bolt.Sips, as: Neo
  alias OhMyAdolf.Wiki.WikiURL

  def transaction(func) do
    Neo.transaction(Neo.conn(), func)
  end

  def get_shortest_path(
        conn \\ Neo.conn(),
        %WikiURL{} = start_url,
        %WikiURL{} = end_url
      ) do
    start_hash = enc(start_url)
    end_hash = enc(end_url)

    conn
    |> Neo.query("""
      MATCH
        (start:Page {url_hash: '#{start_hash}'}),
        (end:Page {url_hash: '#{end_hash}'}),
        path = shortestPath((start)-[:REFERS_TO*]-(end))
      RETURN path;
    """)
    |> case do
      {:error, %Neo.Error{message: m, code: c}} ->
        Logger.critical(
          "Could not fetch the shortest path;" <>
            " error code: #{inspect(c)}, message: #{inspect(m)}"
        )

        {:error, :not_found}

      {:ok, resp} ->
        with {:ok, path} <- extract_path(resp) do
          {:ok, path_to_urls(path)}
        end
    end
  end

  def exists?(conn \\ Neo.conn(), %WikiURL{} = url) do
    url_hash = enc(url)

    conn
    |> Neo.query("""
      MATCH (p:Page {url_hash: '#{url_hash}'})
      RETURN COUNT(p) > 0 AS exists
    """)
    |> case do
      {:ok, resp} ->
        Enum.at(resp.results, 0)["exists"]

      {:error, _err} = err ->
        err
    end
  end

  def register_path(conn \\ Neo.conn(), [_ | _] = path) do
    hash_urls =
      path
      |> Enum.map(&enc/1)
      |> Enum.map(&~s('#{&1}'))
      |> Enum.join(",")

    conn
    |> Neo.query("""
    // Hashes
    WITH [#{hash_urls}] AS url_hash_list

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
    """)
  end

  defp extract_path(%Neo.Response{results: []}) do
    {:error, :not_found}
  end

  defp extract_path(%Neo.Response{results: [%{"path" => path}]}) do
    {:ok, path}
  end

  defp path_to_urls(%Neo.Types.Path{} = path) do
    path
    |> Neo.Types.Path.graph()
    |> Stream.filter(fn
      %Neo.Types.Node{} -> true
      _ -> false
    end)
    |> Stream.map(fn node -> node.properties["url_hash"] end)
    |> Enum.map(&dec/1)
  end

  defp dec(url_hash) do
    url_hash |> Base.decode64!() |> WikiURL.new!()
  end

  defp enc(%WikiURL{} = url) do
    url |> WikiURL.to_string() |> Base.encode64()
  end
end
