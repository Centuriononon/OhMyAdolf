defmodule OhMyAdolf.Wiki.Exception do
  defmacro __using__(_) do
    quote do
      defstruct message: nil
      @enforce_keys [:message]

      def new(message), do: %__MODULE__{message: message}
    end
  end
end
