defmodule OhMyAdolf.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Neo4j driver
      {Bolt.Sips, Application.get_env(:bolt_sips, Bolt)},
      # Throttler for rate limitting outbound traffic
      {OhMyAdolf.Throttle,
       [
         server_name: OhMyAdolf.PoisonProxy,
         rate_per_sec:
           Application.get_env(:oh_my_adolf, :poison_proxy)[:rate_per_sec]
       ]},
      # Common task supervisor
      {Task.Supervisor, name: OhMyAdolf.TaskSupervisor},
      OhMyAdolfWeb.Telemetry,
      {DNSCluster,
       query: Application.get_env(:oh_my_adolf, :dns_cluster_query) || :ignore},
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
