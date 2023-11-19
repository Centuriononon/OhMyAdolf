defmodule OhMyAdolf.Wiki.ParserBehavior do
  @type options() :: {:exclude, [URI.t()]}
  @callback extract_wiki_urls(raw_html :: binary(), options :: [options()]) ::
              {:ok, [binary()]} | {:error, Exception.t()}

  @callback extract_wiki_urls(raw_html :: binary()) ::
              {:ok, [binary()]} | {:error, Exception.t()}
end
