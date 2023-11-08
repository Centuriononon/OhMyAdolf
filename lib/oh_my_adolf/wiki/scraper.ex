defmodule OhMyAdolf.Wiki.Scraper do
  @moduledoc """
  Parses and scrapes wiki pages.
  """

  @behaviour OhMyAdolf.Scraper
  @content "div#bodyContent"

  @impl true
  def uniq_urls(page, config \\ default_config()) when is_bitstring(page) do
    api = validate!(config, :api_client)

    case Floki.parse_document(page) do
      {:ok, document} ->
        urls =
          document
          |> Floki.find(@content)
          |> Floki.find("a")
          |> Floki.attribute("href")
          |> Stream.map(&api.absolute_path/1)
          |> Stream.filter(&api.api_url?/1)
          |> Stream.reject(&category_url?/1)
          |> Stream.uniq()
          |> Enum.to_list()

        {:ok, urls}

      _ ->
        {:error, :bad_parse}
    end
  end

  defp category_url?(url) do
    URI.to_string(url) =~ ~r/\/wiki\/Category:/
  end

  defp default_config() do
    Application.get_env(:oh_my_adolf, :wiki_api)
  end

  defp validate!(config, :api_client) do
    Keyword.get(config, :api_client, OhMyAdolf.Wiki.APIClient)
  end
end
