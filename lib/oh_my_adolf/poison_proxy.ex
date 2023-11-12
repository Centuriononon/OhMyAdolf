defmodule OhMyAdolf.PoisonProxy do
  use HTTPoison.Base
  alias OhMyAdolf.Throttle

  @timeout Application.compile_env(
             :oh_my_adolf,
             [:poison_proxy, :queue_timeout],
             5_000
           )
  @http_client Application.compile_env(
                 :oh_my_adolf,
                 [:poison_proxy, :http_client],
                 HTTPoison
               )
  @throttle Application.compile_env(
                 :oh_my_adolf,
                 [:poison_proxy, :throttle],
                 OhMyAdolf.PoisonProxy
               )

  @impl true
  def get(url, headers \\ [], options \\ []) do
    case Throttle.ask(@throttle, @timeout) do
      :act -> @http_client.get(url, headers, options)
      :await -> get(url, headers, options)
    end
  end
end
