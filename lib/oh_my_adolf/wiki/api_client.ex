defmodule OhMyAdolf.Wiki.APIClient do
  @behaviour OhMyAdolf.APIClient

  @impl true
  def api_url?(%URI{} = url, config \\ default_config()) do
    host = validate!(config, :host)

    case url do
      %{host: ^host} -> true
      _ -> false
    end
  end

  @impl true
  def absolute_path(path, config \\ default_config()) do
    URI.merge("https://" <> validate!(config, :host), path)
  end

  @impl true
  def fetch(url, config \\ default_config()) do
    http_client = validate!(config, :http_client)
    headers = validate!(config, :headers)
    options = validate!(config, :options)


    case api_url?(url) do
      true -> http_client.get(url, headers, options)
      false -> {:error, :incorrect_url}
    end
  end

  @impl true
  def fetch_page(url, config \\ default_config()) do
    case fetch(url, config) do
      {:ok, %HTTPoison.Response{status_code: 200} = resp} ->
        {:ok, resp.body}

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, "Received response with #{status} status"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      err ->
        err
    end
  end

  defp default_config() do
    Application.get_env(:oh_my_adolf, :wiki_api, [])
  end

  defp validate!(config, :host) do
    Keyword.get(config, :host, "en.wikipedia.org")
  end

  defp validate!(config, :http_client) do
    Keyword.get(config, :http_client, HTTPoison)
  end

  defp validate!(config, :headers) do
    Keyword.get(config, :headers, [{"User-Agent", "OhMyAdolfTracer"}])
  end

  defp validate!(config, :options) do
    Keyword.get(config, :options, [follow_redirect: true])
  end
end
