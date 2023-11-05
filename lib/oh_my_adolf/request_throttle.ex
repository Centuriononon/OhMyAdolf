defmodule OhMyAdolf.RequestThrottle do
  @moduledoc """
  RequestThrottle is a model which provides rate limit for outbound requests.
  """
  alias OhMyAdolf.Throttle
  require Logger

  def start_link(args) do
    args = Map.merge(args, %{server_name: validated!(args, :server_name)})

    Throttle.start_link(args)
  end

  def validated!(args, :server_name) do
    Map.get(args, :server_name, __MODULE__)
  end

  def fetch(pid \\ __MODULE__, link, options \\ []) do
    headers = Keyword.get(options, :headers) || []
    options = Keyword.get(options, :options) || []
    timeout = Keyword.get(options, :timeout) || 20_000

    Task.async(fn -> do_fetch(pid, link, headers, options) end)
    |> Task.await(timeout)
  end

  defp do_fetch(pid, link, headers, options) do
    case Throttle.ask(pid) do
      :act -> HTTPoison.get(link, headers, options)
      :await -> do_fetch(pid, link, headers, options)
    end
  end
end
