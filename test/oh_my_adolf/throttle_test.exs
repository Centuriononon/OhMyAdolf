defmodule OhMyAdolf.ThrottleTest do
  use ExUnit.Case, async: true
  alias OhMyAdolf.Throttle

  describe "Throttle ask/2 test" do
    setup :default_setup

    test "should return :act before the rate is exceeded", params do
      %{rate: rate, pid: pid} = params

      tips = Enum.map(1..rate, fn _ -> Throttle.ask(pid) end)
      assert Enum.all?(tips, &(&1 === :act))
    end

    test "should return :await after the rate is exceeded", params do
      %{rate: rate, pid: pid} = params
      exceed = 12

      tips = Enum.map(1..(rate + exceed), fn _ -> Throttle.ask(pid) end)

      acts = Enum.take(tips, rate)
      awaits = Enum.drop(tips, rate)

      assert Enum.all?(acts, &(&1 === :act))
      assert Enum.all?(awaits, &(&1 === :await))
    end

    test "should restart count 1 second after the last ask", params do
      %{rate: rate, pid: pid} = params

      assert Enum.all?(1..rate, fn _ -> Throttle.ask(pid) === :act end)

      # 10 ms will be a satisfactory error
      Process.sleep(1010)

      assert Enum.all?(1..rate, fn _ -> Throttle.ask(pid) === :act end)
    end
  end

  def default_setup(_ctx) do
    rate = 10
    {:ok, pid} = Throttle.start_link(server_name: nil, rate_per_sec: rate)

    [rate: 10, pid: pid]
  end
end
