defmodule OhMyAdolf.Wiki.Pathfinder do
  require Logger

  @by_crawl Application.compile_env(
                         :oh_my_adolf,
                         [:wiki, :pathfinder_by_crawl],
                         OhMyAdolf.Wiki.Pathfinder.ByCrawl
                       )
  @wiki_url Application.compile_env(
              :oh_my_adolf,
              [:wiki, :wiki_url],
              OhMyAdolf.Wiki.WikiURL
            )
  @paths Application.compile_env(
           :oh_my_adolf,
           [:wiki, :paths],
           OhMyAdolf.Wiki.Pathfinder.Paths
         )

  def find_path(%URI{} = start_url, %URI{} = core_url) do
    start_url = @wiki_url.downcase(start_url)
    core_url = @wiki_url.downcase(core_url)

    if @wiki_url.canonical?(start_url, core_url) do
      {:ok, [core_url]}
    else
      with {:error, _} <- @paths.get_path(start_url, core_url) do
        @by_crawl.find_path(start_url, core_url)
      end
    end
  end
end
