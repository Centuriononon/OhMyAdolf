defmodule OhMyAdolf.GraphRepo do
  @moduledoc """
  This is a model over Bolt.Sips for executing queries over the URL based interface.
  """
  require Logger
  alias Bolt.Sips, as: Neo
  alias OhMyAdolf.GraphRepo.Helpers

  def transaction(func) do
    Neo.transaction(Neo.conn(), func)
  end

  def get_shortest_path(
        conn \\ Neo.conn(),
        %URI{} = start_url,
        %URI{} = end_url
      ) do
    s_str = URI.to_string(start_url)
    e_str = URI.to_string(end_url)
    s_hash = Helpers.enc(s_str)
    e_hash = Helpers.enc(e_str)

    conn
    |> Neo.query("""
      MATCH
        (start:Page {url_hash: '#{s_hash}'}),
        (end:Page {url_hash: '#{e_hash}'}),
        path = shortestPath((start)-[:REFERS_TO*]-(end))
      RETURN path;
    """)
    |> Helpers.log_query_error()
    |> case do
      {:error, %Neo.Error{message: m, code: c}} ->
        Logger.critical(
          "Could not fetch the shortest path;" <>
            " error code: #{inspect(c)}, message: #{inspect(m)}"
        )

        {:error, :not_found}

      {:ok, resp} ->
        with {:ok, path} <- extract_path(resp) do
          {:ok, Helpers.path_to_urls(path)}
        end
    end
  end

  def extract_path(%Neo.Response{results: []}) do
    {:error, :not_found}
  end

  def extract_path(%Neo.Response{results: [%{"path" => path}]}) do
    {:ok, path}
  end

  def register_page_relation(
        conn \\ Neo.conn(),
        %URI{} = abv_url,
        %URI{} = sub_url
      ) do
    abv_str = URI.to_string(abv_url)
    sub_str = URI.to_string(sub_url)
    abv_hash = Helpers.enc(abv_str)
    sub_hash = Helpers.enc(sub_str)

    conn
    |> Neo.query("""
      MERGE (above:Page {url_hash: '#{abv_hash}'})
      MERGE (sub:Page {url_hash: '#{sub_hash}'})
      MERGE (above)-[:REFERS_TO]->(sub) RETURN above, sub;
    """)
    |> Helpers.log_query_error()
  end

  def exists?(conn \\ Neo.conn(), %URI{} = url) do
    url_str = URI.to_string(url)
    url_hash = Helpers.enc(url_str)

    conn
    |> Neo.query("""
      MATCH (p:Page {url_hash: '#{url_hash}'})
      RETURN COUNT(p) > 0 AS exists
    """)
    |> Helpers.log_query_error()
    |> case do
      {:ok, resp} -> Enum.at(resp.results, 0)["exists"]
      {:error, _err} = err -> err
    end
  end

  def register_paths(conn \\ Neo.conn(), [[_ | _] | _] = paths) do
    query =
      paths
      |> Enum.reduce("", fn path, acc_query ->
        query =
          path
          |> Stream.map(&URI.to_string(&1))
          |> Enum.map(&Helpers.enc/1)
          |> Helpers.get_query_register_pages()

        acc_query <> "\n" <> query
      end)

    conn
    |> Neo.query(query)
    |> Helpers.log_query_error()
  end

  def register_path(conn \\ Neo.conn(), [_ | _] = path) do
    query =
      path
      |> Stream.map(&URI.to_string(&1))
      |> Enum.map(&Helpers.enc/1)
      |> Helpers.get_query_register_pages()

    conn
    |> Neo.query("#{query} RETURN abv, sub")
    |> Helpers.log_query_error()
  end
end
