defmodule OhMyAdolf.Wiki.Behaviors.WikiURLBehavior do
  @callback validate_url(URI.t()) ::
              {:ok, URI.t()} | {:error, Exception.t()}

  @callback valid_url?(URI.t()) :: boolean()
  @callback valid_host?(binary()) :: boolean()
  @callback valid_scheme?(binary()) :: boolean()
  @callback absolute_url(binary()) :: URI.t()
  @callback absolute_url?(URI.t()) :: boolean()
  @callback downcase(URI.t()) :: URI.t()
  @callback canonical?(URI.t(), URI.t()) :: boolean()
end
