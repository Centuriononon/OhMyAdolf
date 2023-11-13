defmodule OhMyAdolfWeb.FormLive do
  use OhMyAdolfWeb, :live_view

  def mount(_params, _sessions, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <h1 class="title">OhMy<span class="adolf avg">Adolf</span></h1>
      <div class="form-group">
        <p>Enter wiki URL to some Adolfs 🔎</p>
        <div class="input-group">
          <input type="text" placeholder="Right here">
          <button>Go!</button>
        </div>
      </div>
    </div>
    """
  end

  def handle_event do
  end
end
