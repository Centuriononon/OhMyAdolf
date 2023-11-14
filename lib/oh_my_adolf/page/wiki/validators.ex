defmodule OhMyAdolf.Page.Wiki.Validators do
  alias OhMyAdolf.Page

  @host Application.compile_env(
          :oh_my_adolf,
          [:wiki, :host],
          "en.wikipedia.org"
        )
  @schemas Application.compile_env(:oh_my_adolf, [:wiki, :schemas], ~w(https))

  def valid?(%Page{url: url}), do: valid_url?(url)

  def valid_url?(%URI{} = url) do
    valid_url_host?(url) && valid_url_schema?(url)
  end

  def valid_url_host?(%URI{} = url) do
    url.host === @host
  end

  def valid_url_schema?(%URI{} = url) do
    Enum.member?(@schemas, url.scheme)
  end

  def absolute_url(path) when is_bitstring(path) do
    URI.merge("https://" <> @host, path)
  end
end
