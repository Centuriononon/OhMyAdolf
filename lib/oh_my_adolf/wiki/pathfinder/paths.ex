defmodule OhMyAdolf.Wiki.Pathfinder.Paths do
  @moduledoc """
  This is a model over Bolt.Sips for executing queries over the Wiki based interface.
  """
  require Logger
  alias Bolt.Sips.Types.Node
  alias Bolt.Sips, as: Neo

  @repo Application.compile_env(:oh_my_adolf, [:wiki, :repo], OhMyAdolf.Repo)
  @page_label "Page"
  @page_rel "REFERS_TO"

  def get_path(%URI{} = start_url, %URI{} = end_url) do
    n1 = url_to_node(start_url)
    n2 = url_to_node(end_url)

    IO.puts "get path request with: #{start_url} and #{end_url}"

    with {:ok, path_nodes} <- @repo.get_path(n1, n2, @page_rel) do
      {:ok, nodes_to_urls(path_nodes)}
    end
  end

  def register_path([_ | _] = path) do
    path_nodes = urls_to_nodes(path)

    @repo.transaction(&do_register_path_nodes(&1, path_nodes))
    |> case do
      {:ok, _reply} -> :ok
    end
  end

  defp do_register_path_nodes(conn, [node | nodes]) do
    Enum.reduce(nodes, node, fn sub, above ->
      @repo.chain_nodes(conn, above, sub, @page_rel)
      sub
    end)
  end

  def registered_url?(conn \\ Neo.conn(), %URI{} = url) do
    @repo.node_exists?(conn, url_to_node(url))
  end

  def extend_path([_ | _] = path, %URI{} = core_url) do
    core_node = url_to_node(core_url)
    heading_nodes = urls_to_nodes(path)
    inter_node = List.last(heading_nodes)

    @repo.transaction(fn conn ->
      Logger.debug("Opened transaction to get path by repo extension")

      if @repo.node_exists?(conn, inter_node) do
        Logger.debug("Found the current url registered in the repo")

        case @repo.get_path(conn, inter_node, core_node, @page_rel) do
          {:ok, [_inter_node | tailing_nodes]} ->
            path_nodes = Enum.concat(heading_nodes, tailing_nodes)
            do_register_path_nodes(conn, path_nodes)

            {:ok, path_nodes}

          {:error, _not_found} ->
            {:error, :not_found}
        end
      else
        Logger.error("Not found the current url during transaction")
        {:error, :not_found}
      end
    end)
    |> case do
      {:ok, reply} ->
        with {:ok, path_nodes} <- reply do
          {:ok, nodes_to_urls(path_nodes)}
        end
    end
  end

  defp nodes_to_urls(nodes) do
    Enum.map(nodes, &node_to_url/1)
  end

  defp node_to_url(%Node{properties: %{"url_hash" => url_hash}}) do
    dec(url_hash)
  end

  defp urls_to_nodes(url_hashes) do
    Enum.map(url_hashes, &url_to_node/1)
  end

  defp url_to_node(%URI{} = url) do
    %Node{properties: %{"url_hash" => enc(url)}, labels: [@page_label]}
  end

  defp dec(url_hash), do: url_hash |> Base.decode64!() |> URI.parse()
  defp enc(%URI{} = url), do: url |> URI.to_string() |> Base.encode64()
end
