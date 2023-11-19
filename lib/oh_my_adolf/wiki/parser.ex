defmodule OhMyAdolf.Wiki.Parser do
  @behaviour OhMyAdolf.Wiki.ParserBehavior
  alias OhMyAdolf.Wiki.BadParseError

  @wiki_url Application.compile_env(
              :oh_my_adolf,
              [:wiki, :wiki_url],
              OhMyAdolf.Wiki.WikiURL
            )

  @impl true
  def extract_wiki_urls(html, [exclude: urls_to_exclude] \\ [exclude: []])
      when is_bitstring(html) do
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
          |> exclude_urls(urls_to_exclude)

        {:ok, urls}

      _ ->
        {:error, %BadParseError{}}
    end
  end

  defp exclude_urls(urls, urls_to_exclude) do
    urls
    |> Stream.reject(fn url ->
      Enum.any?(urls_to_exclude, &@wiki_url.canonical?(&1, url))
    end)
  end
end
