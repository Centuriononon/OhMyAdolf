defmodule OhMyAdolf.Pathfinder do
  require Logger

  @graph_repo Application.compile_env(
                :oh_my_adolf,
                :graph_repo,
                OhMyAdolf.GraphRepo
              )
  @crawler Application.compile_env(:oh_my_adolf, :crawler, OhMyAdolf.Crawler)

  def find_path(start_url, core_url) do
    @graph_repo.get_shortest_path(start_url, core_url)
    |> case do
      {:error, _not_found} -> find_by_crawl(start_url, core_url)
      {:ok, path} -> {:ok, path}
    end
  end

  defp find_by_crawl(start_url, core_url) do
    @crawler.crawl(start_url)
    |> Enum.reduce_while(
      {:error, :not_found},
      fn
        {abv_url, url}, not_found_resp ->
          Logger.debug("Processing relation: #{abv_url} --> #{url}")

          @graph_repo.transaction(fn conn ->
            {:ok, _resp} =
              @graph_repo.register_page_relation(conn, abv_url, url)

            @graph_repo.get_shortest_path(conn, start_url, core_url)
          end)
          |> case do
            {:ok, {:ok, path}} -> {:halt, {:ok, path}}
            _ -> {:cont, not_found_resp}
          end
      end
    )
  end
end
