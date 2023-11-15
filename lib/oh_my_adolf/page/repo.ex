defmodule OhMyAdolf.Page.Repo do
  @moduledoc """
  This is a model over Bolt.Sips for executing queries over the URL based interface.
  """
  require Logger
  alias Bolt.Sips, as: Neo
  alias OhMyAdolf.Page

  def transaction(func) do
    Neo.transaction(Neo.conn(), func)
  end

  def get_shortest_path(
        conn \\ Neo.conn(),
        %URI{} = start_url,
        %URI{} = end_url
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
          {:ok, path_to_pages(path)}
        end
    end
  end


  def register_page_relation(
        conn \\ Neo.conn(),
        %Page{} = abv_page,
        %Page{} = sub_page
      ) do
    abv_hash = enc(abv_page.url)
    sub_hash = enc(sub_page.url)

    conn
    |> Neo.query("""
      MERGE (above:Page {url_hash: '#{abv_hash}'})
      MERGE (sub:Page {url_hash: '#{sub_hash}'})
      MERGE (above)-[:REFERS_TO]->(sub);
    """)
  end

  def exists?(conn \\ Neo.conn(), unit)

  def exists?(conn, %Page{url: url}) do
    exists?(conn, url)
  end

  def exists?(conn, %URI{} = url) do
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

  def register_paths(conn \\ Neo.conn(), [[_ | _] | _] = paths) do
    query =
      paths
      |> Enum.reduce("", fn path, acc_query ->
        query = get_query_register_pages(path)

        acc_query <> "\n" <> query
      end)

    Neo.query(conn, query)
  end

  def register_path(conn \\ Neo.conn(), [_ | _] = path) do
    query = get_query_register_pages(path)

    Neo.query(conn, query)
  end

  defp extract_path(%Neo.Response{results: []}) do
    {:error, :not_found}
  end

  defp extract_path(%Neo.Response{results: [%{"path" => path}]}) do
    {:ok, path}
  end

  defp get_query_register_pages(pages) do
    url_hashes =
      pages
      |> Stream.map(fn %Page{url: url} -> url end)
      |> Enum.map(&enc/1)

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

  defp path_to_pages(%Neo.Types.Path{} = path) do
    path
    |> Neo.Types.Path.graph()
    |> Stream.filter(fn
      %Neo.Types.Node{} -> true
      _ -> false
    end)
    |> Stream.map(fn node -> node.properties["url_hash"] end)
    |> Stream.map(&dec/1)
    |> Enum.map(&Page.new/1)
  end

  defp dec(url_hash), do: url_hash |> Base.decode64!() |> URI.parse()
  defp enc(%URI{} = url), do: url |> format_url() |> Base.encode64()
  defp format_url(url), do: url |> URI.to_string() |> String.downcase()
end
