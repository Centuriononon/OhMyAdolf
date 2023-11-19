defmodule OhMyAdolf.Wiki.Fetcher do
  @behaviour OhMyAdolf.Wiki.FetcherBehavior
  require Logger
  alias OhMyAdolf.Wiki.{BadResponseError, BadRequestError}

  @http_client Application.compile_env(
                 :oh_my_adolf,
                 [:wiki, :http_client],
                 HTTPoison
               )
  @options Application.compile_env(:oh_my_adolf, [:wiki, :http_options],
             follow_redirect: true,
             timeout: 20_000
           )
  @headers Application.compile_env(:oh_my_adolf, [:wiki, :http_headers], [])

  @impl true
  def fetch(%URI{} = url) do
    @http_client.get(URI.to_string(url), @headers, @options)
  end

  @impl true
  def fetch_page(%URI{} = url) do
    case fetch(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status}} ->
        exc = BadResponseError.exception(url: url, status: status)
        {:error, exc}

      {:error, %HTTPoison.Error{reason: reason}} ->
        exc = BadRequestError.exception(url: url, reason: reason)
        {:error, exc}
    end
  end
end
