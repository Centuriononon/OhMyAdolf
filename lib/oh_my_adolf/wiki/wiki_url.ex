defmodule OhMyAdolf.Wiki.WikiURL do
  import Kernel, except: [to_string: 1]
  alias OhMyAdolf.Wiki.Exception.InvalidURL

  @host Application.compile_env(
          :oh_my_adolf,
          [:wiki, :host],
          "en.wikipedia.org"
        )
        |> String.downcase()

  def validate_url(%URI{} = uri) do
    if valid_url?(uri) do
      {:ok, uri}
    else
      {:error, InvalidURL.new("Invalid or unsupported url")}
    end
  end

  def valid_url?(%URI{} = uri) do
    valid_url_host?(uri) && valid_url_schema?(uri)
  end

  def valid_url_host?(%URI{host: host}), do: host === @host

  def valid_url_schema?(%URI{} = uri) do
    Enum.member?(~w(http https), uri.scheme)
  end

  def absolute_url(path) when is_bitstring(path) do
    URI.parse("https://" <> @host <> path)
  end

  def format(%URI{} = uri) do
    uri =
      uri
      |> URI.to_string()
      |> String.downcase()
      |> URI.parse()

    Map.merge(uri, %{port: nil, host: @host, schema: "https"})
  end

  def canonical?(%URI{} = u1, %URI{} = u2) do
    format(u1) === format(u2)
  end
end
