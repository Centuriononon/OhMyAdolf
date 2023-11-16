defmodule OhMyAdolf.Wiki do
  alias OhMyAdolf.Wiki.WikiURL

  @validator Application.compile_env(
               :oh_my_adolf,
               [:wiki, :validator],
               OhMyAdolf.Wiki.Validator
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
            |> WikiURL.new!()

  def find_path(%URI{} = uri) do
    with {:ok, url} <- @validator.validated_url(uri) do
      @pathfinder.find_path(url, @core_url)
    end
  end
end
