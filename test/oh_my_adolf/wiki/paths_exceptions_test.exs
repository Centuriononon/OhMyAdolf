defmodule OhMyAdolf.Wiki.PathsExceptionsTest do
  use ExUnit.Case, async: true
  import Mox
  import OhMyAdolf.Test.Support.Wiki.{PathHelpers, Helpers}

  alias OhMyAdolf.RepoMock
  alias OhMyAdolf.Wiki.Paths

  describe "Wiki.Paths get_path/2" do
    test "should transform repo's errors" do
      url_head = URI.parse("https://host/head")
      url_tail = URI.parse("https://host/tail")

      stub(RepoMock, :get_path, fn _conn, _h_n, _t_n ->
        {:error, "some_reason"}
      end)

      assert {:error, :not_found} = Paths.get_path(url_head, url_tail)
    end
  end

  describe "Wiki.Paths extend_path/2" do
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
