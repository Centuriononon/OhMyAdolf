defmodule OhMyAdolfWeb.FormLive do
  use OhMyAdolfWeb, :live_view
  require Logger
  alias OhMyAdolf
  alias OhMyAdolfWeb.PathComponent

  def mount(_params, _sessions, socket) do
    Process.flag(:trap_exit, true)

    socket =
      assign(socket,
        url: "https://en.wikipedia.org/wiki/USSR",
        loading: false,
        message: "",
        task: nil,
        path: []
      )

    {:ok, socket}
  end

  def render(assigns) do
    IO.puts(inspect(assigns))

    ~H"""
      <div class="form-group">
        <%= if @loading do %>
          <p>Loading!</p>
        <% else %>
          <p class="intro">Enter wiki URL to find some Adolfs 🔎</p>
          <div class="input-group">
            <input class="input" value={@url} type="text" placeholder="Right here."/>
            <button class="btn" phx-click="find_path">Go!</button>
          </div>
          <%= if @message do %>
            <span class="warn"><%= @message %></span>
          <% end %>
        <% end %>
        <%= if @path do %>
          <PathComponent.index path={@path}/>
        <% end %>
      </div>
    """
  end

  def handle_event("find_path", _, socket) do
    url = socket.assigns.url

    socket =
      assign(socket,
        loader: true,
        url: "",
        task: OhMyAdolf.find_path_async_no_link(URI.parse(url))
      )

    {:noreply, socket}
  end

  def terminate(reason, %{assigns: %{task: %Task{} = task}}) do
    Logger.debug(
      "Terminating liveview with #{inspect(reason)}. " <>
        " Shutting down current running task"
    )

    Task.shutdown(task)
  end

  def terminate(reason, _socket) do
    Logger.debug(
      "Terminating liveview with #{inspect(reason)}. " <>
        "No tasks to shutdown."
    )
  end

  def handle_info({_ref, {:ok, path}}, socket) do
    Logger.debug("Found the requested path: #{inspect(path)}")

    socket =
      socket
      |> assign(message: nil)
      |> assign(path: path)
      |> assign(loading: false)
      |> assign(task: nil)

    {:noreply, socket}
  end

  def handle_info({_ref, {:error, reason}}, socket) do
    Logger.debug("Could not find the requested path due to #{inspect(reason)}")

    socket =
      socket
      |> assign(message: reason)
      |> assign(loading: false)
      |> assign(task: nil)

    {:noreply, socket}
  end

  def handle_info({_ref, {:exit, reason}}, socket) do
    Logger.error("Cought unexpected task exit with #{inspect(reason)} reason")

    socket =
      socket
      |> assign(message: "Something went wrong but we can start over.")
      |> assign(loading: false)
      |> assign(task: nil)

    {:noreply, socket}
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, socket) do
    Logger.debug("Pathfinding task exited with #{inspect(reason)} reason")

    {:noreply, socket}
  end
end
