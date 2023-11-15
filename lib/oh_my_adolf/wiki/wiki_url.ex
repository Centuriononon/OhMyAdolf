defmodule OhMyAdolf.Wiki.WikiURL do
  import Kernel, except: [to_string: 1]
  alias __MODULE__

  defmodule URIError do
    defexception [:message, :url]
  end

  @enforce_keys [:url]
  defstruct url: nil

  @host Application.compile_env(
          :oh_my_adolf,
          [:wiki, :host],
          "en.wikipedia.org"
        )
        |> String.downcase()

  def new!(uri) when is_bitstring(uri), do: new!(URI.parse(uri))

  def new!(%URI{} = uri) do
    case new(uri) do
      {:ok, url} ->
        url

      {:error, :invalid_url} ->
        raise WikiURL.URIError, uri: uri, message: "Got unsupported wiki-url"
    end
  end

  def new(%URI{} = uri) do
    if valid_url?(uri) do
      {:ok, %WikiURL{url: format_url(uri)}}
    else
      {:error, :invalid_url}
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

  def canonical?(%WikiURL{} = u1, %WikiURL{} = u2) do
    to_string(u1) === to_string(u2)
  end

  def to_string(%WikiURL{url: url}), do: URI.to_string(url)

  def format_url(%URI{} = uri) do
    uri =
      uri
      |> URI.to_string()
      |> String.downcase()
      |> URI.parse()

    Map.merge(uri, %{port: nil, host: @host, schema: "https"})
  end
end

defimpl String.Chars, for: OhMyAdolf.Wiki.WikiURL do
  alias OhMyAdolf.Wiki.WikiURL

  def to_string(%WikiURL{} = url), do: WikiURL.to_string(url)
end
