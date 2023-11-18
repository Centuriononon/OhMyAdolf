defmodule OhMyAdolf.Wiki.WikiURL do
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
    valid_host?(uri.host) &&
      valid_scheme?(uri.scheme)
  end

  def valid_host?(host) when is_bitstring(host) do
    host === @host
  end

  def valid_scheme?(scheme) when is_bitstring(scheme) do
    Enum.member?(~w(http https), scheme)
  end

  def format_path(path) when is_bitstring(path) do
    path
    |> absolute_url()
    |> Map.replace(:fragment, nil)
    |> downcase()
  end

  def absolute_url(path) when is_bitstring(path) do
    URI.parse("https://" <> @host <> path)
  end

  def downcase(%URI{} = uri) do
    uri
    |> URI.to_string()
    |> String.downcase()
    |> URI.parse()
  end

  def canonical?(%URI{} = u1, %URI{} = u2) do
    URI.to_string(downcase(u1)) ===
      URI.to_string(downcase(u2))
  end
end
