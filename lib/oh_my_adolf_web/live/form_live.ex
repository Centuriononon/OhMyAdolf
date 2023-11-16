defmodule OhMyAdolfWeb.FormLive do
  use OhMyAdolfWeb, :live_view
  require Logger
  alias OhMyAdolf
  alias OhMyAdolfWeb.{PathComponent, LoaderComponent}

  def mount(_params, _sessions, socket) do
    Process.flag(:trap_exit, true)

    socket =
      assign(socket,
        url: "https://en.wikipedia.org/wiki/USSR",
        loading: false,
        warning: "",
        task: nil,
        path: []
      )

    {:ok, socket}
  end

  def render(assigns) do
    IO.puts("Current assigns: #{inspect(assigns)}")

    ~H"""
    <div class={"form-container"}>
      <%= if @loading do %>
        <div class={"form-container__blur"}>
          <p class={"blur__message"}>LOADING...</p>
        </div>
      <% end %>
      <p class="form-container__description">Enter wiki URL to find some Adolfs 🔎</p>
      <div class="input-group">
        <input class="input-group__input" value={@url} type="text" placeholder="Right here."/>
        <button class="input-group__button" phx-click="find_path">Go!</button>
      </div>
      <span class="form-container__warning"><%= @warning %></span>
    </div>
    <PathComponent.index path={@path}/>
    """
  end

  def handle_event("find_path", _, socket) do
    url = URI.parse(socket.assigns.url)

    socket =
      socket
      |> assign(loading: true)
      |> assign(url: "")
      |> assign(task: start_path_finding(url))

    {:noreply, socket}
  end

  # Find path result
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

  def terminate(reason, %{assigns: %{task: %Task{} = task}}) do
    Logger.debug("Terminating liveview with #{inspect(reason)}")
    Logger.debug("Shutting down the current running task...")
    Task.shutdown(task)
  end

  def terminate(reason, _socket) do
    Logger.debug("Terminating liveview with #{inspect(reason)}")
  end

  defp start_path_finding(%URI{} = start_url) do
    Task.Supervisor.async_nolink(OhMyAdolf.TaskSupervisor, fn ->
      OhMyAdolf.find_path(start_url)
    end)
  end
end
