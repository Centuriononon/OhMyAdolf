defmodule OhMyAdolf.Wiki.WikiURLBehavior do
  @callback validate_url(url :: URI.t()) ::
              {:ok, URI.t()} | {:error, Exception.t()}

  @callback valid_url?(url :: URI.t()) :: boolean()
  @callback valid_host?(host :: binary()) :: boolean()
  @callback valid_scheme?(scheme :: binary()) :: boolean()
  @callback absolute_url(url :: binary()) :: URI.t()
  @callback absolute_url?(url :: URI.t()) :: boolean()
  @callback downcase(uri :: URI.t()) :: URI.t()
  @callback canonical?(uri :: URI.t(), uri :: URI.t()) :: boolean()
end
