defmodule OhMyAdolf.Wiki.Pathfinder.PathsTest do
  use ExUnit.Case, async: true
  import Mox

  alias OhMyAdolf.Wiki.Pathfinder.Paths
  alias OhMyAdolf.RepoMock
  alias Bolt.Sips.Types.Node

  @page_label "Page"
  @page_rel "REFERS_TO"

  describe "Wiki.Pathfinder.Paths get_path/2" do
    test "should pass repo error" do
      reason = :no_reason

      url_head = URI.parse("https://host/head")
      url_tail = URI.parse("https://host/tail")

      stub(RepoMock, :get_path, fn _conn, _h_n, _t_n ->
        {:error, reason}
      end)

      assert {:error, ^reason} = Paths.get_path(url_head, url_tail)
    end
  end
end
