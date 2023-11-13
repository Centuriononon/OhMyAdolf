defmodule OhMyAdolfWeb.FormLive do
  use OhMyAdolfWeb, :live_view

  def mount(_params, _sessions, socket) do
    socket =
      assign(socket,
        url: "https://en.wikipedia.org/wiki/USSR",
        status: false
      )

    {:ok, socket}
  end

  def render(assigns) do
    # Logic:
    # when the input is filled, button is clicked the input b
    # ecomes a loader (static text for now) and button go becomes unclickable

    # when we get response we put it under the form
    ~H"""
      <div class="form-group">
        <%= if not @status do %>
          <p>Enter wiki URL to find some Adolfs 🔎</p>
          <div class="input-group">
            <input value={@url} type="text" placeholder="Right here."/>
            <button phx-click="find_path">Go!</button>
          </div>
        <% else %>
          <p>Loading!</p>
        <% end %>
      </div>
    """
  end

  def handle_event("find_path", _, socket) do
    url = socket.assigns.url
    socket = assign(socket, status: true, url: "")
    {:noreply, socket}
  end
end
