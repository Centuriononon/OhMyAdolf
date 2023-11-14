defmodule OhMyAdolfWeb.PathComponent do
  use Phoenix.Component

  def index(assigns) do
    ~H"""
    <div>
    <%= for page <- @path do %>
      <p><%= page %></p>
    <% end %>
    </div>
    """
  end
end
