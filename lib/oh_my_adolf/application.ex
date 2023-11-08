defmodule OhMyAdolf.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    http_throttle =
      {OhMyAdolf.Throttle,
       [
         server_name: OhMyAdolf.PoisonProxy,
         rate_per_sec: 200
       ]}

    children = [
      http_throttle,
      OhMyAdolfWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:oh_my_adolf, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: OhMyAdolf.PubSub},
      OhMyAdolfWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OhMyAdolf.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OhMyAdolfWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
