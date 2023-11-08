defmodule OhMyAdolf.APIClient do
  @type config() :: [{:endpoint, String.t()} | {:http_client, module()}]

  @type get_request() ::
          {:ok, HTTPoison.Response.t()}
          | {:error, HTTPoison.Error.t()}

  @callback absolute_path(String.t()) :: URI.t()
  @callback absolute_path(String.t(), config()) :: URI.t()

  @callback fetch(URL.t()) ::
              get_request()
              | {:error, :not_wiki_url}
  @callback fetch(URL.t(), config()) ::
              get_request()
              | {:error, :not_wiki_url}

  @callback fetch_page(URL.t()) ::
              {:ok, String.t()}
              | {:error, HTTPoison.Error.t()}
              | {:error, :not_wiki_url}
  @callback fetch_page(URL.t(), config()) ::
              {:ok, String.t()}
              | {:error, HTTPoison.Error.t()}
              | {:error, :not_wiki_url}
end
