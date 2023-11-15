defmodule OhMyAdolf.Page do
  alias __MODULE__

  @enforce_keys [:url]
  defstruct url: nil

  def new(%URI{} = url) do
    %Page{url: url}
  end

  def canonical?(%Page{} = p1, %Page{} = p2) do
    canonical?(p1.url, p2.url)
  end

  def canonical?(%URI{} = u1, %URI{} = u2) do
    standard_url(u1) === standard_url(u2)
  end

  def standard_url(%Page{url: url}), do: standard_url(url)

  def standard_url(%URI{} = url) do
    url
    |> URI.merge(%{url | port: nil, scheme: "http"})
    |> URI.to_string()
    |> String.downcase()
  end
end
