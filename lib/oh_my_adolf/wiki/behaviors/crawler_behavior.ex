defmodule OhMyAdolf.Wiki.CrawlerBehavior do
  @callback crawl(start_url :: URI.t()) :: Enum.t()
end
