defmodule OhMyAdolf.Page do
  alias __MODULE__

  @enforce_keys [:url]
  defstruct url: nil

  def new(%URI{} = url) do
    %Page{url: url}
  end

  def equal?(%Page{} = p1, %Page{} = p2) do
    standard_url(p1.url) === standard_url(p2.url)
  end

  defp standard_url(%URI{} = url) do
    url |> URI.to_string() |> String.downcase()
  end
end
