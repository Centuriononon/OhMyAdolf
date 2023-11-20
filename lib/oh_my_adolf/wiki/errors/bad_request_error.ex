defmodule OhMyAdolf.Wiki.BadRequestError do
  defexception [:message, :url, :reason]

  @impl true
  def exception(url: %URI{} = url, reason: reason)
      when is_bitstring(reason) or is_atom(reason) do
    msg = "Could not request #{url} due to #{reason}"
    %__MODULE__{message: msg, url: url, reason: reason}
  end
end
