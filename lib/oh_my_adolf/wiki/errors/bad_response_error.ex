defmodule OhMyAdolf.Wiki.Errors.BadResponseError do
  defexception [:message]

  def exception(url: %URI{} = url, status: status) when is_number(status) do
    msg = "Received status code #{status} requesting #{url}"
    %__MODULE__{message: msg}
  end
end
