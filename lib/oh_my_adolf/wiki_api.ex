defmodule OhMyAdolf.WikiAPI do
  @behaviour GenServer

  alias OhMyAdolf.RequestThrottle

  @rate_per_sec 200
  @host "en.wikipedia.org"

  def start_link(args \\ %{}) do
    RequestThrottle.start_link(%{
      rate_per_sec: @rate_per_sec,
      server_name: Map.get(args, :server_name, __MODULE__)
    })
  end

  defdelegate init(args), to: RequestThrottle

  def valid_url?(link) when is_bitstring(link) do
    case URI.parse(link) do
      %URI{scheme: "http", host: @host} -> true
      %URI{scheme: "https", host: @host} -> true
      _ -> false
    end
  end

  def fetch(pid \\ __MODULE__, link) do
    case valid_url?(link) do
      true -> RequestThrottle.fetch(pid, link)
      false -> {:error, :invalid_url}
    end
  end

  def fetch_page(pid \\ __MODULE__, link) do
    case fetch(pid, link) do
      {:ok, %HTTPoison.Response{status_code: 200} = resp} ->
        {:ok, resp}

      {:ok, resp} ->
        {:error, resp}

      rest ->
        rest
    end
  end
end
