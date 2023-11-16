defmodule OhMyAdolf.Wiki.Validator do
  alias OhMyAdolf.Wiki.WikiURL
  alias OhMyAdolf.Wiki.Exception.InvalidURL

  def validated_url(%URI{} = uri) do
    with {:error, :invalid_url} <- WikiURL.new(uri) do
      {:error, InvalidURL.new("Invalid or unsupported url")}
    end
  end
end
