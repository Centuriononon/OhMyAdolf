defmodule OhMyAdolfWeb.PathComponent do
  use Phoenix.Component
  alias OhMyAdolf.Wiki.WikiURL

  def index(assigns) do
    ~H"""
    <div class="path-container">
    <%= for %WikiURL{url: url} <- @path do %>
      <div class="path-container__url-container"><%= to_string(url) %></div>
    <% end %>
    </div>
    """
  end
end
