defmodule OhMyAdolf do
  @moduledoc """
  OhMyAdolf keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require Logger
  alias __MODULE__

  @wiki_pages Application.compile_env(
                :oh_my_adolf,
                :wiki_pages,
                OhMyAdolf.WikiPages
              )

  # from 1 hop: "https://en.wikipedia.org/wiki/Nazism"
  # from 2 hops: "https://en.wikipedia.org/wiki/Far-right_politics"
  # Long: "https://en.wikipedia.org/wiki/Penguin"
  # |> URI.parse |> OhMyAdolf.find_path
  defdelegate find_path(url), to: @wiki_pages
end
