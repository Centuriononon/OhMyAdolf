defmodule OhMyAdolf.Wiki.Parser do
  alias OhMyAdolf.Wiki.Exception.{FailedParse}

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
          |> Stream.map(&@wiki_url.format_path/1)
          |> Stream.reject(&Enum.member?(urls, &1))

        IO.puts "URLS: #{inspect(urls)}"
        {:ok, urls}

      _ ->
        exc = FailedParse.new("Could not parse document")
        {:error, exc}
    end
  end
end
