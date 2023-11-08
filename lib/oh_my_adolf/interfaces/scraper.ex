defmodule OhMyAdolf.Scraper do
  @doc """
  Parses and scrapes HTML documents.
  """

  @callback uniq_urls(String.t()) ::
              {:ok, list(URI.t())}
              | {:error, :bad_parse}
end
