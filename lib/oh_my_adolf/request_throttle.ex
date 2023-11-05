defmodule OhMyAdolf.RequestThrottle do
  @moduledoc """
  RequestThrottle is a model which provides rate limit for outbound requests.
  """
  @behaviour GenServer
  alias OhMyAdolf.Throttle
  require Logger

  def start_link(args) do
    Throttle.start_link(
      Map.merge(
        args, %{server_name: Map.get(args, :server_name, __MODULE__)}
      )
    )
  end

  defdelegate init(args), to: Throttle

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
