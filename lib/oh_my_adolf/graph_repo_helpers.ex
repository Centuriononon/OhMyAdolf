defmodule OhMyAdolf.GraphRepo.Helpers do
  require Logger
  alias Bolt.Sips, as: Neo


  def path_to_urls(%Neo.Types.Path{} = path) do
    path
    |> Neo.Types.Path.graph
    |> Stream.filter(fn
      %Neo.Types.Node{} -> true
      _ -> false
    end)
    |> Stream.map(fn node -> node.properties["url_hash"] end)
    |> Stream.map(&dec/1)
    |> Enum.map(&URI.parse/1)
  end

  def get_query_register_pages(url_hashes) do
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

  def log_query_error({:error, %Neo.Error{message: m, code: c}} = r) do
    Logger.critical(
      "Could not register path;" <>
        " error code: #{inspect(c)}, message: #{inspect(m)}"
    )

    r
  end

  def log_query_error(r), do: r

  def dec(url) when is_bitstring(url), do: Base.decode64!(url)
  def enc(url) when is_bitstring(url), do: Base.encode64(url)
end
