defmodule OhMyAdolfWeb.FormLive do
  use OhMyAdolfWeb, :live_view
  require Logger
  alias OhMyAdolf
  alias OhMyAdolfWeb.PathComponent

  @host Application.get_env(:oh_my_adolf, [:wiki, :host], "en.wikipedia.org")
  @def_placeholder "Like here."
  @def_url "https://" <> @host <> "/wiki/Far-right_politics"

  def mount(_params, _sessions, socket) do
    Process.flag(:trap_exit, true)

    socket =
      assign(socket,
        url: @def_url,
        placeholder: @def_placeholder,
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
    <form
      class="form-container"
      phx-submit={"#{ if @loading, do: 'stop_search', else: 'start_search'}"}
    >
      <p class="form-container__description">
        Enter wiki URL to find some Adolfs 🔎
      </p>
      <div class="input-group">
        <input
          class="input-group__input"
          value={@url}
          name="url"
          type="text"
          placeholder={@placeholder}
          disabled={@loading}/>
      <%= if @loading do %>
        <button
          class="input-group__button button__cancel">Stop</button>
      <% else %>
        <button class="input-group__button">Go!</button>
      <% end %>
      </div>
      <span class="form-container__warning"><%= @warning %></span>
    </form>
    <PathComponent.index path={@path}/>
    """
  end

  def handle_event("start_search", %{"url" => ""}, socket) do
    socket =
      socket
      |> assign(warning: "Don't skip the field!")

    {:noreply, socket}
  end

  def handle_event("start_search", params, %{assigns: %{task: nil}} = socket) do
    uri = params["url"] |> String.trim(" ") |> URI.parse()

    socket =
      socket
      |> assign(loading: true)
      |> assign(warning: nil)
      |> assign(url: "")
      |> assign(placeholder: "Loading...")
      |> assign(task: start_path_finding(uri))

    {:noreply, socket}
  end

  def handle_event("start_search", _, socket) do
    {:noreply, socket}
  end

  def handle_event("stop_search", _, %{assigns: %{task: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_event("stop_search", _, %{assigns: %{task: task}} = socket) do
    Task.shutdown(task)

    socket =
      socket
      |> assign(loading: false)
      |> assign(placeholder: @def_placeholder)

    {:noreply, socket}
  end

  # Find path result
  def handle_info({_ref, {:ok, path}}, socket) do
    Logger.debug("Found the requested path: #{inspect(path)}")

    socket =
      socket
      |> assign(url: "")
      |> assign(placeholder: @def_placeholder)
      |> assign(warning: nil)
      |> assign(path: path)
      |> assign(loading: false)
      |> assign(task: nil)

    {:noreply, socket}
  end

  def handle_info({_ref, {:error, exception}}, socket) do
    Logger.debug(
      "Could not find the requested path due to #{inspect(exception.message)}"
    )

    socket =
      socket
      |> assign(placeholder: @def_placeholder)
      |> assign(warning: exception.message)
      |> assign(loading: false)
      |> assign(task: nil)

    {:noreply, socket}
  end

  def handle_info({_ref, {:exit, reason}}, socket) do
    Logger.error("Cought unexpected task exit with #{inspect(reason)} reason")

    socket =
      socket
      |> assign(placeholder: @def_placeholder)
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
