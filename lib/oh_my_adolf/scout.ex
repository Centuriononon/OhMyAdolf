defmodule OhMyAdolf.Scout do
  @moduledoc """
  Scout model is used to perform
  """

  @graph_repo Application.compile_env(
                :oh_my_adolf,
                :graph_repo,
                OhMyAdolf.GraphRepo
              )

  @doc """
  Designates a path in the graph repo and returns the final
  path from the first url of the passed path to the final url.
  """
  def designate_final_path(passed_path, dest_url) do
    fn ->
      passed_path
      |> Enum.find_value(fn url ->
        @graph_repo.get_shortest_path(url, dest_url)
        |> case do
          {:ok, path} ->
            @graph_repo.register_path(passed_path)
            {:ok, path}

          _ ->
            nil
        end
      end)
      |> case do
        {:ok, path} -> {:ok, path}
        _ -> {:error, "could not designate"}
      end
    end
    |> @graph_repo.transaction()
  end
end
