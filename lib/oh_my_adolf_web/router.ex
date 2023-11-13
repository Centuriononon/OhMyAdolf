defmodule OhMyAdolfWeb.Router do
  use OhMyAdolfWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OhMyAdolfWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", OhMyAdolfWeb do
    pipe_through :browser

    live "/", FormLive
  end
end
