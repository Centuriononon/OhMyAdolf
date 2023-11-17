defmodule OhMyAdolf.Wiki.Pathfinder do
  require Logger

  @pathfinder_by_crawl Application.compile_env(
                         :oh_my_adolf,
                         [:wiki, :pathfinder_by_crawl],
                         OhMyAdolf.Wiki.Pathfinder.ByCrawl
                       )
  @wiki_url Application.compile_env(
              :oh_my_adolf,
              [:wiki, :wiki_url],
              OhMyAdolf.Wiki.WikiURL
            )
  @repo Application.compile_env(
          :oh_my_adolf,
          [:wiki, :repo],
          OhMyAdolf.Wiki.Repo
        )

  def find_path(%URI{} = start_url, %URI{} = core_url) do
    start_url = @wiki_url.format(start_url)
    core_url = @wiki_url.format(core_url)

    if @wiki_url.canonical?(start_url, core_url) do
      {:ok, [core_url]}
    else
      with {:error, _} <- @repo.get_shortest_path(start_url, core_url) do
        @pathfinder_by_crawl.find_path(start_url, core_url)
      end
    end
  end
end
