defmodule OhMyAdolf.Wiki.APIClient do
  require Logger

  @http_client Application.compile_env(:oh_my_adolf, :http_client, HTTPoison)
  @host Application.compile_env(:oh_my_adolf, :wiki_host, HTTPoison)
  @timeout Application.compile_env(:oh_my_adolf, :wiki_api_timeout, 30_000)

  def api_url?(%URI{} = url) do
    host = @host

    case url do
      %{host: ^host} -> true
      _ -> false
    end
  end

  def absolute_path(path) do
    URI.merge("https://" <> @host, path)
  end

  def fetch(%URI{} = url) do
    Logger.debug("Fetching: #{url}")

    case api_url?(url) do
      true ->
        @http_client.get(
          url,
          [{"User-Agent", "OhMyAdolfTracer"}],
          follow_redirect: true,
          timeout: @timeout
        )

      false ->
        {:error, :incorrect_url}
    end
  end

  def fetch_page(%URI{} = url) do
    case fetch(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: s}} ->
        {:error, "received response with #{s} status"}

      {:error, %HTTPoison.Error{reason: r}} ->
        {:error, "httpoison error: " <> to_string(r)}

      {:error, _reason} = err ->
        err
    end
  end
end
