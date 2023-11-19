defmodule OhMyAdolf.Wiki.Errors.BadRequestError do
  defexception [:message]

  @impl true
  def exception(url: %URI{} = url, reason: reason) when is_bitstring(reason) do
    msg = "Could not request #{url} due to #{reason}"
    %__MODULE__{message: msg}
  end
end
