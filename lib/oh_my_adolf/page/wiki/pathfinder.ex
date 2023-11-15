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
    |> Enum.reduce_while({Graph.new(), start_url, core_url}, &handle_emit/2)
    |> case do
      {:found, path} -> {:ok, path}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :not_found}
    end
  end

  defp handle_emit({:error, %Page{} = page, reason}, state) do
    Logger.error("Could not scrape #{page.url} due to #{inspect(reason)}")
    {:cont, state}
  end

  defp handle_emit(
         {:ok, %Page{url: abv_url}, %Page{url: sub_url}},
         {graph, start_url, core_url}
       ) do
    Logger.debug("Processing relation: #{abv_url} --> #{sub_url}")

    abv_ref = Page.standard_url(abv_url)
    sub_ref = Page.standard_url(sub_url)

    graph = Graph.add_edge(graph, abv_ref, sub_ref)

    if Page.canonical?(sub_url, core_url) do
      start_ref = Page.standard_url(start_url)
      path = Graph.get_shortest_path(graph, start_ref, sub_ref)

      {:halt, {:found, path}}
    else
      {:cont, {graph, start_url, core_url}}
    end
  end
end
