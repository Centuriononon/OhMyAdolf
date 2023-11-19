defmodule OhMyAdolf.Wiki.NotFoundPathError do
  defexception [:message]

  def exception(message) when is_bitstring(message) do
    %__MODULE__{message: message}
  end
end
