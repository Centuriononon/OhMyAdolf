defmodule OhMyAdolf.Scout do
  @moduledoc """
  Scout model is used to perform
  """
  require Logger

  @graph_repo Application.compile_env(
                :oh_my_adolf,
                :graph_repo,
                OhMyAdolf.GraphRepo
              )

  @doc """
  Designates a path in the graph repo and returns the final
  path from the first url of the passed path to the final url.
  """
  def designate_final_path(passed_path, core_url) do
    fn ->
      Enum.reduce_while(passed_path, [], fn curr_url, acc_urls ->
        curr_path = [curr_url] ++ acc_urls

        # mb check in pipe
        if @graph_repo.exists?(curr_url) do
          {:ok, path} = @graph_repo.get_shortest_path(curr_url, core_url)
          :ok = @graph_repo.register_path(curr_path)

          {:halt, {:found, acc_urls ++ path}}
        else
          {:cont, curr_path}
        end
      end)
      |> case do
        {:found, path} ->
          {:ok, path}

        _ ->
          {:error, "not found"}
      end
    end
    |> @graph_repo.transaction()
  end
end
