defmodule OhMyAdolf.Page.Fetcher do
  require Logger
  alias OhMyAdolf.Page

  def fetch(%Page{url: url}, config), do: fetch(url, config)

  def fetch(%URI{} = url, config) do
    options = config[:options] || []
    headers = config[:headers] || []

    http_client =
      config[:http_client] ||
        raise ArgumentError.exception(":http_client arg is required")

    Logger.debug("Fetching: #{url}")
    http_client.get(url, headers, options)
  end

  def fetch_page(%Page{url: url}, config), do: fetch_page(url, config)

  def fetch_page(%URI{} = url, config) do
    case fetch(url, config) do
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
