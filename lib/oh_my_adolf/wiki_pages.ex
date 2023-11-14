defmodule OhMyAdolf.WikiPages do
  @validators Application.compile_env(
                :oh_my_adolf,
                [:wiki, :page_validator],
                OhMyAdolf.Page.Wiki.Validators
              )

  @pathfinder Application.compile_env(
                :oh_my_adolf,
                [:wiki, :pathfinder],
                OhMyAdolf.Page.Wiki.Pathfinder
              )

  @core_url Application.compile_env!(
              :oh_my_adolf,
              [:wiki, :core_url]
            )
            |> URI.parse()

  def find_path(url) when is_bitstring(url) do
    find_path(URI.parse(url))
  end

  def find_path(%URI{} = url) do
    with {:ok, url} <- validate_url(url) do
      @pathfinder.find_path(url, @core_url)
    end
  end

  def validate_url(url) when is_bitstring(url) do
    validate_url(URI.parse(url))
  end

  def validate_url(%URI{} = url) do
    if @validators.valid_url?(url) do
      {:ok, url}
    else
      {:error, :invalid_url}
    end
  end
end
