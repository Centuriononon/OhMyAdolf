defmodule OhMyAdolf.Wiki.BadResponseError do
  defexception [:message, :status_code, :url]

  def exception(url: %URI{} = url, status: status) when is_number(status) do
    msg = "Received status code #{status} requesting #{url}"
    %__MODULE__{message: msg, url: url, status_code: status}
  end
end
