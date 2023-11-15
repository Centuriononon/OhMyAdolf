defmodule OhMyAdolf.Wiki.Fetcher do
  require Logger
  alias OhMyAdolf.Wiki.WikiURL

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
        {:error, "received response with #{status} status"}

      {:error, %HTTPoison.Error{reason: r}} ->
        {:error, "httpoison error: " <> to_string(r)}

      {:error, _reason} = err ->
        err
    end
  end
end
