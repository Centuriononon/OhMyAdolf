defmodule OhMyAdolf.Wiki.Pathfinder.ByRepo do
  require Logger
  alias OhMyAdolf.Wiki.Pathfinder.Helpers

  @repo Application.compile_env(
          :oh_my_adolf,
          [:wiki, :repo],
          OhMyAdolf.Wiki.Repo
        )

  def find_path_by_extention(
        graph,
        %URI{} = start_url,
        %URI{} = sub_url,
        %URI{} = core_url
      ) do
    # initial check to avoid transaction overhead
    if @repo.exists?(sub_url) do
      do_find_path_by_extention(graph, start_url, sub_url, core_url)
    else
      {:error, :not_found}
    end
  end

  defp do_find_path_by_extention(graph, start_url, sub_url, core_url) do
    # Taking the accumulated heading path
    heading_path =
      Task.async(fn ->
        Helpers.get_shortest_path_from_graph(graph, start_url, sub_url)
      end)
      |> Task.await(10_000)

    @repo.transaction(fn conn ->
      Logger.debug("Opened transaction to get path by repo extension")

      # if current url is registered already
      if @repo.exists?(conn, sub_url) do
        Logger.debug("Found the current url registered in the repo")

        # then get the path from the current url to the core one
        case @repo.get_shortest_path(conn, sub_url, core_url) do
          {:ok, [_sub_page | tailing_path]} ->
            Logger.debug("Found the tailing path from the url")

            # merging the paths
            final_path = Enum.concat(heading_path, tailing_path)

            # register the final paths
            @repo.register_path(conn, final_path)

            {:ok, final_path}

          {:error, _not_found} ->
            Logger.error("Not found the tailing path from the url")
            {:error, :not_found}
        end
      else
        Logger.error("Not found the current url during transaction")
        {:error, :not_found}
      end
    end)
    |> case do
      {:ok, reply} ->
        reply

      {:error, reason} ->
        Logger.critical("Could not perform transaction due to #{reason}")
        {:error, :not_found}
    end
  end
end
