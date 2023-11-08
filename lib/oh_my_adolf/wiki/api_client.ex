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
    validate!(config, :endpoint) |> URI.merge(path)
  end

  @impl true
  def fetch(url, config \\ default_config()) do
    http_client = validate!(config, :http_client)

    case api_url?(url) do
      true -> http_client.get(url)
      false -> {:error, :incorrect_url}
    end
  end

  @impl true
  def fetch_page(url, config \\ default_config()) do
    case fetch(url, config) do
      {:ok, %HTTPoison.Response{status_code: 200} = resp} ->
        {:ok, resp.body}

      rest ->
        rest
    end
  end

  defp default_config() do
    Application.get_env(:oh_my_adolf, :wiki_api)
  end

  defp validate!(config, :host) do
    Keyword.get(config, :host, "en.wikipedia.org")
  end

  defp validate!(config, :http_client) do
    Keyword.get(config, :http_client, HTTPoison)
  end
end
