defmodule OhMyAdolf.Wiki.APIClient do
  @behaviour OhMyAdolf.APIClient

  def wiki_url?(%URI{} = url, config \\ default_config()) do
    endpoint = URI.new(config[:endpoint])
    host = endpoint.host
    scheme = endpoint.scheme

    case url do
      %{host: ^host, scheme: ^scheme} -> true
      _ -> false
    end
  end

  @impl true
  def absolute_path(path, config \\ default_config()) do
    URI.merge(config[:endpoint], path)
  end

  @impl true
  def fetch(url, config \\ default_config()) do
    http_client = Keyword.get(config, :http_client)

    case wiki_url?(url) do
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
end
