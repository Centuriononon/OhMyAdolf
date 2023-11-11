defmodule OhMyAdolf.GraphRepo do
  @moduledoc """
  This is a model over Bolt.Sips for executing queries over the interface.
  """
  # alias Bolt.Sips, as: Neo

  # def transaction(func), do: Neo.transaction(Neo.conn(), func)
  def transaction(func), do: func.()

  def get_shortest_path(%URI{} = _s, %URI{} = _e) do
  #   s_str = URI.to_string(s)
  #   e_str = URI.to_string(e)

  #   Neo.conn()
  #   |> Neo.query("""
  #     MATCH path = shortestPath((start:LABEL {url: '#{s_str}'})-[:REFERS_TO*]-(end:LABEL {url: #{e_str}}))
  #     RETURN path;
  #   """)
  {:error, "not found"} # or {:ok, [URI.t()]}
  end

  def register_path(_urls) do
    :ok
  end
end
