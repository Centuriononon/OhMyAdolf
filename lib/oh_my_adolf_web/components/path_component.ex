defmodule OhMyAdolfWeb.PathComponent do
  use Phoenix.Component

  def index(assigns) do
    ~H"""
    <div class="path-container">
    <%= for url <- @path do %>
      <div class="path-container__url-block">
        <p class="url-block__url"><%= to_string(url) %></p>
      </div>
    <% end %>
    </div>
    """
  end
end
