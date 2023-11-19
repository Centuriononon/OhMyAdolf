defmodule OhMyAdolf.Wiki.WikiURL do
  @behaviour OhMyAdolf.Wiki.Behaviors.WikiURLBehavior
  alias OhMyAdolf.Wiki.Errors.InvalidURLError

  @host Application.compile_env(
          :oh_my_adolf,
          [:wiki, :host],
          "en.wikipedia.org"
        )
        |> String.downcase()

  @impl true
  def validate_url(%URI{} = uri) do
    if valid_url?(uri) do
      {:ok, uri}
    else
      {:error, %InvalidURLError{}}
    end
  end

  @impl true
  def valid_url?(%URI{} = uri) do
    valid_host?(uri.host) &&
      valid_scheme?(uri.scheme)
  end

  @impl true
  def valid_host?(host) do
    host === @host
  end

  @impl true
  def valid_scheme?(scheme) do
    Enum.member?(~w(http https), scheme)
  end

  @impl true
  def absolute_url(path) when is_bitstring(path) do
    uri = URI.parse(path)

    if absolute_url?(uri) do
      uri
    else
      URI.parse("https://" <> @host <> path)
    end
  end

  @impl true
  def absolute_url?(%URI{} = url) do
    is_bitstring(url.host) && is_bitstring(url.scheme)
  end

  @impl true
  def downcase(%URI{} = uri) do
    uri
    |> URI.to_string()
    |> String.downcase()
    |> URI.parse()
  end

  @impl true
  def canonical?(%URI{} = u1, %URI{} = u2) do
    URI.to_string(downcase(u1)) ===
      URI.to_string(downcase(u2))
  end
end
