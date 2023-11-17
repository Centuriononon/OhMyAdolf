defmodule OhMyAdolfWeb.FormLive do
  use OhMyAdolfWeb, :live_view
  require Logger
  alias OhMyAdolf
  alias OhMyAdolfWeb.PathComponent

  @host Application.compile_env(
          :oh_my_adolf,
          [:wiki, :host],
          "en.wikipedia.org"
        )
  @def_placeholder "Like here."
  @def_url "https://" <> @host <> "/wiki/Far-right_politics"

  def mount(_params, _sessions, socket) do
    Process.flag(:trap_exit, true)

    socket =
      assign(socket,
        url: @def_url,
        placeholder: @def_placeholder,
        loading: false,
        message: "",
        warn_message?: false,
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
      <span class={"#{
        if @warn_message?,
          do: 'form-container__message_alert',
          else: 'form-container__message'
        }"}><%= @message %></span>
    </form>
    <PathComponent.index path={@path}/>
    """
  end

  def handle_event("start_search", %{"url" => ""}, socket) do
    socket =
      socket
      |> assign(message: "Don't skip the field!")
      |> assign(warn_message?: true)

    {:noreply, socket}
  end

  def handle_event("start_search", params, %{assigns: %{task: nil}} = socket) do
    uri = params["url"] |> String.trim(" ") |> URI.parse()

    socket =
      socket
      |> assign(loading: true)
      |> assign(message: nil)
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

  def handle_event("stop_search", _, %{assigns: %{task: pid}} = socket) do
    stop_path_finding(pid)

    socket =
      socket
      |> assign(loading: false)
      |> assign(task: nil)
      |> assign(warn_message?: false)
      |> assign(message: "The search is stopped. Brutally.")
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
      |> assign(warn_message?: false)
      |> assign(message: "The search is complete.")
      |> assign(path: path)

    {:noreply, socket}
  end

  def handle_info({_ref, {:error, exception}}, socket) do
    Logger.debug(
      "Could not find the requested path due to #{inspect(exception.message)}"
    )

    socket =
      socket
      |> assign(placeholder: @def_placeholder)
      |> assign(warn_message?: true)
      |> assign(message: exception.message)

    {:noreply, socket}
  end

  def handle_info({:EXIT, _pid, reason}, socket) do
    Logger.debug("Pathfinding task is exitting with #{inspect(reason)} reason")

    socket =
      socket
      |> assign(placeholder: @def_placeholder)
      |> assign(loading: false)
      |> assign(task: nil)

    {:noreply, socket}
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, socket) do
    Logger.debug("Pathfinding task is down with #{inspect(reason)} reason")
    {:noreply, socket}
  end

  def terminate(reason, %{assigns: %{task: nil}}) do
    Logger.debug("Terminating liveview with #{inspect(reason)}")
  end

  def terminate(reason, %{assigns: %{task: pid}}) do
    Logger.debug("Terminating liveview with #{inspect(reason)}")
    Logger.debug("Shutting down the current running task...")
    stop_path_finding(pid)
  end

  defp stop_path_finding(task) do
    Task.shutdown(task)
  end

  defp start_path_finding(%URI{} = start_url) do
    Task.Supervisor.async(OhMyAdolf.TaskSupervisor, fn ->
      OhMyAdolf.find_path(start_url)
    end)
  end
end
