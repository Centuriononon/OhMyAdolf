defmodule OhMyAdolf do
  @moduledoc """
  OhMyAdolf keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require Logger

  @pathfinder Application.compile_env(
                :oh_my_adolf,
                :pathfinder,
                OhMyAdolf.Pathfinder
              )
  @core_url Application.compile_env(
              :oh_my_adolf,
              :core_url,
              "https://en.wikipedia.org/wiki/Adolf_Hitler"
            ) |> URI.parse()

  # Short: "https://en.wikipedia.org/wiki/Nazism" |> URI.parse |> OhMyAdolf.find_path()
  # Long: "https://en.wikipedia.org/wiki/Penguin" |> URI.parse |> OhMyAdolf.find_path()
  def find_path(%URI{} = start_url) do
    @pathfinder.find_path(start_url, @core_url)
  end
end
