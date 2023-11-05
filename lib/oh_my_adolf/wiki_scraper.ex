defmodule OhMyAdolf.WikiScraper do
  @moduledoc """
  WikiScraper is a model which is used to scrap wikipedia pages.
  """

  @content "div#bodyContent"

  def scrap_links(body) do
    body
    |> Floki.parse_document()
    |> case do
      {:ok, doc} ->
        doc
        |> Floki.find(@content)
        |> Floki.find("a[href]")
      _ -> {:error, "Could not parse"}
    end
  end
end
