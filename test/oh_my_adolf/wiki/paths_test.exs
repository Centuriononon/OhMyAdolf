defmodule OhMyAdolf.Wiki.PathsTest do
  use ExUnit.Case, async: true
  import Mox
  import OhMyAdolf.Test.Support.Wiki.{Helpers, PathHelpers}

  alias OhMyAdolf.Wiki.Paths
  alias OhMyAdolf.RepoMock

  @page_rel "REFERS_TO"

  describe "Wiki.Paths get_path/2" do
    test "should transform urls to nodes" do
      page_rel = @page_rel

      url_head = URI.parse("https://host/head")
      url_tail = URI.parse("https://host/tail")

      node_head = get_node(url_head)
      node_tail = get_node(url_tail)

      expect(
        RepoMock,
        :get_path,
        fn ^node_head, ^node_tail, ^page_rel ->
          {:ok, []}
        end
      )

      Paths.get_path(url_head, url_tail)
    end

    test "should transform nodes to urls" do
      url_head = URI.parse("https://host/head")
      url_tail = URI.parse("https://host/tail")

      urls = gen_urls(3)

      stub(
        RepoMock,
        :get_path,
        fn _, _, _ ->
          {:ok, Enum.map(urls, &get_node/1)}
        end
      )

      assert {:ok, ^urls} = Paths.get_path(url_head, url_tail)
    end
  end

  describe "Wiki.Paths register_path/1" do
    test "should chain within transaction" do
      page_rel = @page_rel

      expect(
        RepoMock,
        :transaction,
        fn func -> {:ok, func.(:db_conn)} end
      )

      stub(
        RepoMock,
        :chain_nodes,
        fn
          :db_conn, _h_n, _t_n, ^page_rel -> :ok
        end
      )

      Paths.register_path(gen_urls(2))
    end

    test "should chain each node" do
      page_rel = @page_rel

      expect(
        RepoMock,
        :transaction,
        fn func -> {:ok, func.(:db_conn)} end
      )

      nodes = gen_nodes(4)

      Enum.reduce(
        Enum.drop(nodes, 1),
        Enum.at(nodes, 0),
        fn sub, abv ->
          expect(
            RepoMock,
            :chain_nodes,
            fn :db_conn, ^abv, ^sub, ^page_rel -> :ok end
          )

          sub
        end
      )

      assert :ok = Paths.register_path(gen_urls(4))
    end
  end

  describe "Wiki.Paths registered_url?/2" do
    test "should transform url to node" do
      url = URI.parse("http://host/path")
      node = get_node(url)

      expect(
        RepoMock,
        :node_exists?,
        fn
          _, ^node -> true
        end
      )

      Paths.registered_url?(url)
    end

    test "should provide the repo's result" do
      stub(RepoMock, :node_exists?, fn _conn, _node -> true end)

      assert true = Paths.registered_url?(%URI{})

      stub(RepoMock, :node_exists?, fn _conn, _node -> false end)

      assert false === Paths.registered_url?(%URI{})
    end

    test "should use the same conn" do
      expect(RepoMock, :node_exists?, fn :db_conn, _node -> true end)

      Paths.registered_url?(:db_conn, %URI{})
    end
  end

  describe "Wiki.Paths extend_path/2" do
    test "should extend within transaction (no inter node case)" do
      expect(
        RepoMock,
        :transaction,
        fn func -> {:ok, func.(:db_conn)} end
      )

      expect(RepoMock, :node_exists?, fn :db_conn, _node -> false end)

      Paths.extend_path(gen_urls(2), %URI{})
    end

    test "should extend within transaction (no path case)" do
      expect(
        RepoMock,
        :transaction,
        fn func -> {:ok, func.(:db_conn)} end
      )

      expect(RepoMock, :node_exists?, fn :db_conn, _node -> true end)

      expect(RepoMock, :get_path, fn :db_conn, _h_n, _t_n, _rel ->
        {:error, :not_found}
      end)

      Paths.extend_path(gen_urls(2), %URI{})
    end

    test "should extend within transaction" do
      expect(
        RepoMock,
        :transaction,
        fn func -> {:ok, func.(:db_conn)} end
      )

      expect(RepoMock, :node_exists?, fn :db_conn, _node -> true end)

      expect(RepoMock, :get_path, fn :db_conn, _h_n, _t_n, _rel ->
        {:ok, gen_nodes(2)}
      end)

      # the heading nodes (initial) + the tailing nodes (by get_path)
      expect(RepoMock, :chain_nodes, 4, fn :db_conn, _n_1, _n_2, _rel ->
        :ok
      end)

      Paths.extend_path(gen_urls(2), %URI{})
    end

    test "should merge heading urls with found tailing urls" do
      page_rel = @page_rel

      expect(
        RepoMock,
        :transaction,
        fn func -> {:ok, func.(:db_conn)} end
      )

      core_url = URI.parse("http://host/core")
      core_node = get_node(core_url)

      heading_urls = gen_urls(3)

      inter_url = List.last(heading_urls)
      inter_node = get_node(inter_url)

      tailing_urls = [inter_url] ++ gen_urls(3, 5) ++ [core_url]
      tailing_nodes = Enum.map(tailing_urls, &get_node/1)

      expect(RepoMock, :node_exists?, fn _conn, ^inter_node -> true end)

      expect(RepoMock, :get_path, fn _conn,
                                     ^inter_node,
                                     ^core_node,
                                     ^page_rel ->
        {:ok, tailing_nodes}
      end)

      stub(RepoMock, :chain_nodes, fn _conn, _n_1, _n_2, _rel ->
        :ok
      end)

      final_path =
        heading_urls ++ Enum.drop(tailing_urls, 1)

      assert {:ok, ^final_path} = Paths.extend_path(heading_urls, core_url)
    end

    test "should chain found path nodes" do
      page_rel = @page_rel

      expect(
        RepoMock,
        :transaction,
        fn func -> {:ok, func.(:db_conn)} end
      )

      core_url = URI.parse("http://host/core")

      heading_urls = gen_urls(2)

      inter_url = List.last(heading_urls)

      tailing_urls = [inter_url] ++ gen_urls(2, 4) ++ [core_url]
      tailing_nodes = Enum.map(tailing_urls, &get_node/1)

      final_path = heading_urls ++ Enum.drop(tailing_urls, 1)
      final_nodes = Enum.map(final_path, &get_node/1)

      expect(RepoMock, :node_exists?, fn _conn, _node -> true end)

      expect(RepoMock, :get_path, fn _conn, _h_n, _t_n, ^page_rel ->
        {:ok, tailing_nodes}
      end)

      Enum.reduce(
        Enum.drop(final_nodes, 1),
        Enum.at(final_nodes, 0),
        fn sub, abv ->
          expect(
            RepoMock,
            :chain_nodes,
            fn
              :db_conn, ^abv, ^sub, ^page_rel -> :ok
            end
          )

          sub
        end
      )

      assert {:ok, ^final_path} = Paths.extend_path(heading_urls, core_url)
    end
  end
end
