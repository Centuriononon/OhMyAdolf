defmodule OhMyAdolf.Wiki do
  alias OhMyAdolf.Wiki.WikiURL

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
    with {:ok, url} <- WikiURL.new(uri) do
      @pathfinder.find_path(url, @core_url)
    end
  end

  def validate_uri(%URI{} = url) do
    if WikiURL.valid_url?(url) do
      {:ok, url}
    else
      {:error, :invalid_url}
    end
  end
end
