defmodule OhMyAdolf.Wiki.PathsBehavior do
  @callback get_path(start_url :: URI.t(), end_url :: URI.t()) ::
              {:ok, list(URI.t())} | {:error, :not_found}

  @callback register_path(path)
            :: :ok when path: nonempty_list(URI.t())

  @callback registered_url?(url :: URI.t()) :: boolean()

  @callback extend_path(path :: list(URI.t()), core_url :: URI.t()) ::
              {:ok, list(URI.t())} | {:error, :not_found}
end
