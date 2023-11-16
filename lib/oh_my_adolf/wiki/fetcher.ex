defmodule OhMyAdolf.Wiki.Fetcher do
  require Logger
  alias OhMyAdolf.Wiki.WikiURL
  alias OhMyAdolf.Wiki.Exception.{UnsuccessfulResponse, FailedFetch}

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

  def fetch(%WikiURL{} = url) do
    @http_client.get(WikiURL.to_string(url), @headers, @options)
  end

  def fetch_page(%WikiURL{} = url) do
    case fetch(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status}} ->
        exc =
          UnsuccessfulResponse.new("Received response with #{status} status")

        {:error, exc}

      {:error, %HTTPoison.Error{reason: r}} ->
        exc =
          FailedFetch.new("Got unexpected httpoison error: " <> to_string(r))

        {:error, exc}
    end
  end
end
