defmodule OhMyAdolf.APIClient do
  @type config() :: [{:endpoint, String.t()} | {:http_client, module()}]

  @type get_request() ::
          {:ok, HTTPoison.Response.t()}
          | {:error, HTTPoison.Error.t()}

  @callback absolute_path(String.t()) :: URI.t()
  @callback absolute_path(String.t(), config()) :: URI.t()

  @callback api_url?(URI.t()) :: boolean()
  @callback api_url?(URI.t(), config()) :: boolean()

  @callback fetch(URL.t()) ::
              get_request()
              | {:error, String.t()}
  @callback fetch(URL.t(), config()) ::
              get_request()
              | {:error, String.t()}

  @callback fetch_page(URL.t()) ::
              {:ok, String.t()}
              | {:error, String.t()}
  @callback fetch_page(URL.t(), config()) ::
              {:ok, String.t()}
              | {:error, String.t()}
end
