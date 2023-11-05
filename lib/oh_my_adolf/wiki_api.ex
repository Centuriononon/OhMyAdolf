defmodule OhMyAdolf.WikiAPI do
  @behaviour GenServer

  alias OhMyAdolf.RequestThrottle

  @rate_per_sec 200
  @host "en.wikipedia.org"
  @scheme "https"

  def start_link(args) do
    RequestThrottle.start_link(%{
      rate_per_sec: @rate_per_sec,
      server_name: Map.get(args, :server_name, __MODULE__)
    })
  end

  defdelegate init(args), to: RequestThrottle

  def valid_url?(link) when is_bitstring(link) do
    case URI.parse(link) do
      %URI{scheme: @scheme, host: @host} -> true
      _ -> false
    end
  end
end
