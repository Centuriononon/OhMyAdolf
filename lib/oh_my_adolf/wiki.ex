defmodule OhMyAdolf.Wiki do
  @wiki_url Application.compile_env(
               :oh_my_adolf,
               [:wiki, :validator],
               OhMyAdolf.Wiki.WikiURL
             )

  @pathfinder Application.compile_env(
                :oh_my_adolf,
                [:wiki, :pathfinder],
                OhMyAdolf.Wiki.Pathfinder
              )

  @core_url Application.compile_env!(
              :oh_my_adolf,
              [:wiki, :core_url]
            )
            |> URI.parse()

  def find_path(%URI{} = uri) do
    with {:ok, url} <- @wiki_url.validate_url(uri) do
      @pathfinder.find_path(url, @core_url)
    end
  end
end
