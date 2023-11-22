defmodule OhMyAdolf.Wiki.Pathfinder.ByCrawlBehavior do
  alias OhMyAdolf.Wiki.NotFoundPathError

  @callback find_path(start_url :: URI.t(), core_url :: URI.t()) ::
              {:error, NotFoundPathError.t()} | {:ok, nonempty_list(URI.t())}
end
