defmodule OhMyAdolf.Page.Wiki.Pathfinder do
  require Logger
  alias OhMyAdolf.Page

  @crawler Application.compile_env(
             :oh_my_adolf,
             [:wiki, :page_crawler],
             OhMyAdolf.Page.Wiki.Crawler
           )
  @repo Application.compile_env(
          :oh_my_adolf,
          [:wiki, :page_repo],
          OhMyAdolf.GraphRepo
        )

  def find_path(%URI{} = start_url, %URI{} = core_url) do
    @repo.get_shortest_path(start_url, core_url)
    |> case do
      {:error, _not_found} -> find_by_crawl(start_url, core_url)
      {:ok, path} -> {:ok, path}
    end
  end

  defp find_by_crawl(start_url, core_url) do
    @crawler.crawl(start_url)
    |> Enum.reduce_while({start_url, core_url}, &handle_emit/2)
    |> case do
      {:found, path} -> {:ok, path}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :not_found}
    end
  end

  defp handle_emit({:error, %URI{} = url, reason}, _) do
    Logger.error("Could not start crawling #{url} due to #{inspect(reason)}")
    {:halt, {:error, reason}}
  end

  defp handle_emit({:error, %Page{url: url}, reason}, state) do
    Logger.error("Could not scrape #{url} due to #{inspect(reason)}")
    {:cont, state}
  end

  defp handle_emit(
         {:ok, %Page{url: abv_url}, %Page{url: url}},
         {start_url, core_url} = state
       ) do
    Logger.debug("Processing relation: #{abv_url} --> #{url}")

    @repo.transaction(fn conn ->
      {:ok, _resp} =
        @repo.register_page_relation(conn, abv_url, url)

      @repo.get_shortest_path(conn, start_url, core_url)
    end)
    |> case do
      {:ok, {:ok, path}} ->
        {:halt, {:found, path}}

      _ ->
        {:cont, state}
    end
  end
end
