defmodule OhMyAdolf.Wiki.ScraperBehavior do
  @callback scrape(URI.t()) :: {:ok, {URI.t(), [URI.t()]}} | {:error, Exception.t()}
end
