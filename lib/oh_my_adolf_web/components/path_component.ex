defmodule OhMyAdolfWeb.LoaderComponent do
  use Phoenix.Component
  alias OhMyAdolf.Wiki.WikiURL

  def index(assigns) do
    ~H"""
    <div>
    <%= for %WikiURL{url: url} <- @path do %>
      <p><%= to_string(url) %></p>
    <% end %>
    </div>
    """
  end
end
