defmodule OhMyAdolf.Wiki.Parser do
  alias OhMyAdolf.Wiki.Errors.BadParseError

  @wiki_url Application.compile_env(
              :oh_my_adolf,
              [:wiki, :wiki_url],
              OhMyAdolf.Wiki.WikiURL
            )

  def extract_wiki_urls(html, exclude: urls) when is_bitstring(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        urls =
          document
          |> Floki.find("div#bodyContent")
          |> Floki.find("a")
          |> Floki.attribute("href")
          |> Stream.map(&@wiki_url.absolute_url/1)
          |> Stream.map(&@wiki_url.downcase/1)
          |> Stream.filter(&@wiki_url.valid_url?/1)
          |> Stream.reject(&Enum.member?(urls, &1))

        {:ok, urls}

      _ ->
        {:error, %BadParseError{}}
    end
  end
end
