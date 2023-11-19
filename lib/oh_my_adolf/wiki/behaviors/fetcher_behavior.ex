defmodule OhMyAdolf.Wiki.FetcherBehavior do
  @callback fetch(url :: URI.t()) ::
              {:ok, HTTPoison.Response.t()} | {:error, Exception.t()}

  @callback fetch_page(url :: URI.t()) ::
              {:ok, binary()} | {:error, Exception.t()}
end
