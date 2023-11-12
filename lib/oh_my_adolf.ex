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
              :core_url
            )
            |> URI.parse()

  # 1 hop: "https://en.wikipedia.org/wiki/Nazism"
  # 2 hops: "https://en.wikipedia.org/wiki/Far-right_politics"
  # Long: "https://en.wikipedia.org/wiki/Penguin"
  # |> URI.parse |> OhMyAdolf.find_path
  def find_path(%URI{} = start_url) do
    @pathfinder.find_path(start_url, @core_url)
  end
end
