defmodule OhMyAdolf.Throttle do
  @moduledoc """
  Throttle is a GenServer which provides rate limiting for actions.
  """
  use GenServer
  require Logger

  def start_link(args) do
    server_name = validated!(args, :server_name)
    args = %{rate_per_sec: validated!(args, :rate_per_sec)}

    GenServer.start_link(__MODULE__, args, name: server_name)
  end

  defp validated!(args, :server_name) do
    Keyword.get(args, :server_name, __MODULE__)
  end

  defp validated!(args, :rate_per_sec) do
    value = args[:rate_per_sec]

    if is_number(value) do
      value
    else
      throw(ArgumentError.message(":rate_per_sec arg is mandatory"))
    end
  end

  @impl true
  def init(args) do
    Logger.debug("Starting Throttle server with args: #{inspect(args)}")

    state = %{
      count: 0,
      rate_per_sec: args.rate_per_sec
    }

    schedule_ticker()

    {:ok, state}
  end

  def ask(pid \\ __MODULE__), do: GenServer.call(pid, :ask)

  @impl true
  def handle_call(:ask, _from, state) do
    %{count: count, rate_per_sec: rate} = state

    if count < rate do
      {:reply, :act, Map.merge(state, %{count: count + 1})}
    else
      {:reply, :await, state}
    end
  end

  @impl true
  def handle_info(:tick, state) do
    schedule_ticker()
    {:noreply, Map.merge(state, %{count: 0})}
  end

  defp schedule_ticker() do
    Process.send_after(self(), :tick, 1000)
  end
end
