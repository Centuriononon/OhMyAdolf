defmodule OhMyAdolf.Test.Support.Wiki.PathHelpers do
  import OhMyAdolf.Test.Support.Wiki.Helpers

  alias Bolt.Sips.Types.Node

  @page_label "Page"

  def gen_nodes(from \\ 1, n) do
    Enum.map(gen_urls(from, n), &get_node/1)
  end

  def get_node(%URI{} = url) do
    url |> to_string() |> Base.encode64() |> get_node()
  end

  def get_node(url_hash) do
    %Node{
      labels: [@page_label],
      properties: %{"url_hash" => url_hash}
    }
  end
end
