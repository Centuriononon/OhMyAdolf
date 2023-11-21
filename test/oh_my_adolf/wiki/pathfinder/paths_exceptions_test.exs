defmodule OhMyAdolf.Wiki.Pathfinder.PathsExceptionsTest do
  use ExUnit.Case, async: true
  import Mox
  import OhMyAdolf.Test.Support.WikiPathHelpers

  alias OhMyAdolf.RepoMock
  alias OhMyAdolf.Wiki.Pathfinder.Paths

  describe "Wiki.Pathfinder.Paths get_path/2" do
    test "should except repo's errors" do
      reason = :no_reason

      url_head = URI.parse("https://host/head")
      url_tail = URI.parse("https://host/tail")

      stub(RepoMock, :get_path, fn _conn, _h_n, _t_n ->
        {:error, reason}
      end)

      assert {:error, ^reason} = Paths.get_path(url_head, url_tail)
    end
  end

  describe "Wiki.Pathfinder.Paths extend_path/2" do
    test "should except no inter node case" do
      stub(RepoMock, :transaction, fn fun ->
        {:ok, fun.(:db_conn)}
      end)

      urls = gen_urls(2)
      inter_node = get_node(List.last(urls))

      expect(RepoMock, :node_exists?, fn _conn, ^inter_node -> false end)

      assert {:error, :not_found} = Paths.extend_path(urls, %URI{})
    end

    test "should except no path case" do
      stub(RepoMock, :transaction, fn fun ->
        {:ok, fun.(:db_conn)}
      end)

      urls = gen_urls(2)
      stub(RepoMock, :node_exists?, fn _conn, _n -> true end)

      expect(RepoMock, :get_path, fn _conn, _h_n, _t_n, _rel ->
        {:error, :not_found}
      end)

      assert {:error, :not_found} = Paths.extend_path(urls, %URI{})
    end
  end
end
