defmodule OhMyAdolf.RepoBehavior do
  alias Bolt.Sips.Types.Node

  @callback transaction(fun) :: DBConnection.t()

  @callback get_path(
              head_node :: Node.t(),
              tail_node :: Node.t(),
              relationship :: bitstring()
            ) ::
              {:ok, [Node.t()]} | {:error, atom()}

  @callback get_path(
              DBConnection.conn(),
              head_node :: Node.t(),
              tail_node :: Node.t(),
              relationship :: bitstring()
            ) ::
              {:ok, [Node.t()]} | {:error, atom()}

  @callback node_exists?(node :: Node.t()) :: boolean()
  @callback node_exists?(DBConnection.conn(), node :: Node.t()) :: boolean()

  @callback chain_nodes(
              DBConnection.conn(),
              above_node :: Node.t(),
              sub_node :: Node.t(),
              relationship :: bitstring()
            ) :: :ok | {:error, atom()}
end
