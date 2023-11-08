defmodule OhMyAdolf.Wiki.Scraper do
  @moduledoc """
  Parses and scrapes wiki pages.
  """
  require Logger

  @behaviour OhMyAdolf.Scraper
  @content "div#bodyContent"

  @impl true
  def uniq_urls(page) when is_bitstring(page) do
    case Floki.parse_document(page) do
      {:ok, document} ->
        urls =
          document
          |> Floki.find(@content)
          |> Floki.find("a")
          |> Floki.attribute("href")
          |> Stream.map(&API.relative_path_to_url/1)
          |> Stream.filter(&API.wiki_url?/1)
          |> Stream.reject(&category_url?/1)
          |> Stream.uniq()
          |> Enum.to_list()

        {:ok, urls}

      _ ->
        {:bad_parse}
    end
  end

  defp category_url?(url) do
    URI.to_string(url) =~ ~r/\/wiki\/Category:/
  end
end
