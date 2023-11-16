defmodule OhMyAdolfWeb.LoaderComponent do
  use Phoenix.Component

  def index(assigns) do
    ~H"""
    <p>Loading!</p>
    """
  end
end
