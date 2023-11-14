defmodule OhMyAdolf.Page.Wiki.Fetcher do
  require Logger
  alias OhMyAdolf.Page

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

  def fetch(%Page{url: url}), do: fetch(url)

  def fetch(%URI{} = url) do
    Logger.debug("Fetching: #{url}")
    @http_client.get(url, @headers, @options)
  end

  def fetch_page(%Page{url: url}), do: fetch_page(url)

  def fetch_page(%URI{} = url) do
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
