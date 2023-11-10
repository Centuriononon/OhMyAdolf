defmodule OhMyAdolf.Scraper do
  @doc """
  Parses and scrapes HTML documents.
  """

  @callback uniq_urls(String.t()) ::
              {:ok, Enum.t(URI.t())}
              | {:error, String.t()}
end
