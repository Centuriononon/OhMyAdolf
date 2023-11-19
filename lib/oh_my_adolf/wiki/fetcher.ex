defmodule OhMyAdolf.Wiki.Fetcher do
  require Logger
  alias OhMyAdolf.Wiki.Exception.{BadResponse, BadRequest}

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

  def fetch(%URI{} = url) do
    @http_client.get(URI.to_string(url), @headers, @options)
  end

  def fetch_page(%URI{} = url) do
    case fetch(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status}} ->
        exc =
          BadResponse.new("Received response with #{status} status")

        {:error, exc}

      {:error, %HTTPoison.Error{reason: r}} ->
        exc =
          BadRequest.new("Received httpoison error: " <> to_string(r))

        {:error, exc}
    end
  end
end
