defmodule OhMyAdolf.PoisonProxy do
  use HTTPoison.Base
  alias OhMyAdolf.Throttle

  @impl true
  def get(url, headers \\ [], options \\ [], config \\ default_config()) do
    timeout = validate!(config, :timeout)

    Task.async(fn -> do_get(url, headers, options, config) end)
    |> Task.await(timeout)
  end

  defp do_get(url, headers, options, config) do
    timeout = validate!(config, :timeout)
    throttle = validate!(config, :throttle)
    http_client = validate!(config, :http_client)

    case Throttle.ask(throttle, timeout) do
      :act -> http_client.get(url, headers, options)
      :await -> do_get(url, headers, options, config)
    end
  end

  defp default_config() do
    Application.get_env(:oh_my_adolf, :poison_proxy)
  end

  defp validate!(config, :timeout) do
    Keyword.get(config, :timeout, 5_000)
  end

  defp validate!(config, :throttle) do
    Keyword.get(config, :throttle, __MODULE__)
  end

  defp validate!(config, :http_client) do
    Keyword.get(config, :http_client, HTTPoison)
  end
end
