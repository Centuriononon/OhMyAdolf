defmodule OhMyAdolf.Wiki.Scraper do
  @moduledoc """
  Scraper is a model which is used to scrap wikipedia pages.
  """
  alias OhMyAdolf.Wiki.API

  @content "div#bodyContent"

  def scrap_links(body) do
    body
    |> Floki.parse_document()
    |> case do
      {:ok, doc} ->
        doc
        |> Floki.find(@content)
        |> Floki.find("a")
        |> Floki.attribute("href")
        |> Enum.map(&API.rel_path_to_url/1)
      _ -> {:error, "Could not parse"}
    end
  end
end
