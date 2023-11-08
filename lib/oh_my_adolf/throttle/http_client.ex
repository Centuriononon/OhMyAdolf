defmodule OhMyAdolf.Throttle.HTTPClient do
  use HTTPoison.Base
  alias OhMyAdolf.Throttle

  @impl true
  def get(url, headers \\ [], options \\ [], config \\ default_config()) do
    timeout = config[:timeout]

    Task.async(fn -> do_get(url, headers, options, config) end)
    |> Task.await(timeout)
  end

  defp do_get(url, headers, options, config) do
    server_name = config[:server_name]
    http_client = config[:http_client]

    case Throttle.ask(server_name) do
      :act -> http_client.get(url, headers, options)
      :await -> do_get(url, headers, options, config)
    end
  end

  def default_config() do
    Keyword.merge(
      [timeout: 8000, server_name: __MODULE__, http_client: HTTPoison],
      Application.get_env(:oh_my_adolf, :throttle_http_client)
    )
  end
end
