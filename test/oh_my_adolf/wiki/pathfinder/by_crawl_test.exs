defmodule OhMyAdolf.Wiki.Pathfinder.ByCrawlTest do
  use ExUnit.Case, async: true

  import Mox
  import OhMyAdolf.Test.Support.Wiki.Helpers

  alias OhMyAdolf.Wiki.Pathfinder.ByCrawl
  alias OhMyAdolf.Wiki.CrawlerMock
  alias OhMyAdolf.Wiki.PathsMock
  alias OhMyAdolf.Wiki.WikiURLMock
  alias OhMyAdolf.Wiki.NotFoundPathError

  describe "Wiki.Pathfinder.ByCrawl find_path/2" do
    test "should identify first emitted core url and stop" do
      start_url = URI.parse("http://host/1")
      core_url = URI.parse("http://host/core")

      expect(CrawlerMock, :crawl, fn ^start_url ->
        [{:ok, start_url, core_url}]
      end)

      expect(
        WikiURLMock,
        :canonical?,
        fn ^core_url, ^core_url -> true end
      )

      stub(PathsMock, :register_path, fn _path -> :ok end)

      assert {:ok, [^start_url, ^core_url]} =
               ByCrawl.find_path(start_url, core_url)
    end

    test "should return exception on stream end" do
      start_url = URI.parse("http://host/start")
      core_url = URI.parse("http://host/core")

      streamed = [{:ok, start_url, %URI{}}]

      expect(CrawlerMock, :crawl, fn ^start_url -> streamed end)

      stub(
        WikiURLMock,
        :canonical?,
        fn
          ^core_url, ^core_url -> true
          _, _ -> false
        end
      )

      stub(PathsMock, :registered_url?, fn _url -> false end)

      assert {:error, %NotFoundPathError{}} =
               ByCrawl.find_path(start_url, core_url)
    end

    test "should skip errored url until the core one and stop" do
      start_url = URI.parse("http://host/1")
      core_url = URI.parse("http://host/core")

      expect(CrawlerMock, :crawl, fn ^start_url ->
        [
          {:error, :no_reason, %URI{}},
          {:error, :no_reason, %URI{}},
          {:ok, start_url, core_url},
          {:error, :no_reason, %URI{}}
        ]
      end)

      expect(
        WikiURLMock,
        :canonical?,
        fn
          ^core_url, ^core_url -> true
          _, _ -> false
        end
      )

      stub(PathsMock, :register_path, fn _path -> :ok end)

      assert {:ok, [^start_url, ^core_url]} =
               ByCrawl.find_path(start_url, core_url)
    end

    test "should find path in multilayered graph" do
      mid_path = gen_urls(5)
      start_url = URI.parse("http://host/start")
      core_url = URI.parse("http://host/core")
      path = [start_url] ++ mid_path ++ [core_url]

      streamed =
        [
          {:ok, start_url, Enum.at(mid_path, 0)},
          {:ok, start_url, %URI{}},
          {:ok, Enum.at(mid_path, 0), Enum.at(mid_path, 1)},
          {:ok, Enum.at(mid_path, 1), Enum.at(mid_path, 2)},
          {:error, :no_reason, %URI{}},
          {:ok, Enum.at(mid_path, 2), Enum.at(mid_path, 3)},
          {:ok, Enum.at(mid_path, 3), Enum.at(mid_path, 4)},
          {:ok, Enum.at(mid_path, 3), Enum.at(mid_path, 2)},
          {:ok, Enum.at(mid_path, 3), Enum.at(mid_path, 2)},
          {:ok, Enum.at(mid_path, 4), core_url}
        ]

      expect(CrawlerMock, :crawl, fn ^start_url -> streamed end)

      expect(
        WikiURLMock,
        :canonical?,
        length(streamed),
        fn
          ^core_url, ^core_url -> true
          _, _ -> false
        end
      )

      stub(PathsMock, :register_path, fn _path -> :ok end)
      stub(PathsMock, :registered_url?, fn _url -> false end)

      assert {:ok, ^path} =
               ByCrawl.find_path(start_url, core_url)
    end

    test "should register path from multilayered graph" do
      mid_path = gen_urls(5)
      start_url = URI.parse("http://host/start")
      core_url = URI.parse("http://host/core")
      path = [start_url] ++ mid_path ++ [core_url]

      streamed =
        [
          {:ok, start_url, Enum.at(mid_path, 0)},
          {:ok, start_url, %URI{}},
          {:ok, Enum.at(mid_path, 0), Enum.at(mid_path, 1)},
          {:ok, Enum.at(mid_path, 1), Enum.at(mid_path, 2)},
          {:error, :no_reason, %URI{}},
          {:ok, Enum.at(mid_path, 2), Enum.at(mid_path, 3)},
          {:ok, Enum.at(mid_path, 3), Enum.at(mid_path, 4)},
          {:ok, Enum.at(mid_path, 3), Enum.at(mid_path, 2)},
          {:ok, Enum.at(mid_path, 3), Enum.at(mid_path, 2)},
          {:ok, Enum.at(mid_path, 4), core_url}
        ]

      expect(CrawlerMock, :crawl, fn ^start_url -> streamed end)

      stub(
        WikiURLMock,
        :canonical?,
        fn
          ^core_url, ^core_url -> true
          _, _ -> false
        end
      )

      expect(PathsMock, :register_path, fn ^path -> :ok end)
      stub(PathsMock, :registered_url?, fn _url -> false end)

      ByCrawl.find_path(start_url, core_url)
    end

    test "should try extend path on each non-core url" do
      path = gen_urls(5)
      core_url = List.last(path)
      start_url = List.first(path)

      {streamed, _} =
        Enum.reduce(
          Enum.drop(path, 1),
          {[], start_url},
          fn sub, {acc, abv} ->
            {acc ++ [{:ok, abv, sub}], sub}
          end
        )

      expect(CrawlerMock, :crawl, fn ^start_url -> streamed end)

      stub(
        WikiURLMock,
        :canonical?,
        fn
          ^core_url, ^core_url -> true
          _, _ -> false
        end
      )

      stub(PathsMock, :register_path, fn _path -> :ok end)

      Enum.reduce(
        Enum.drop(path, 1),
        start_url,
        fn sub, _abv ->
          expect(PathsMock, :registered_url?, fn ^sub -> false end)

          sub
        end
      )

      ByCrawl.find_path(start_url, core_url)
    end

    test "should extend path by accumulated path to the core url" do
      path = gen_urls(7)
      core_url = List.last(path)
      start_url = List.first(path)

      heading_path = Enum.take(path, 3)
      inter_url = Enum.at(path, 4)

      streamed_path = heading_path ++ [inter_url]

      {streamed, _} =
        Enum.reduce(
          Enum.drop(streamed_path, 1),
          {[], start_url},
          fn sub, {acc, abv} ->
            {acc ++ [{:ok, abv, sub}], sub}
          end
        )

      expect(CrawlerMock, :crawl, fn ^start_url -> streamed end)

      stub(
        WikiURLMock,
        :canonical?,
        fn
          ^core_url, ^core_url -> true
          _, _ -> false
        end
      )

      stub(PathsMock, :register_path, fn _path -> :ok end)

      stub(PathsMock, :registered_url?, fn
        ^inter_url -> true
        _url -> false
      end)

      expect(PathsMock, :extend_path, fn ^streamed_path, ^core_url ->
        {:ok, path}
      end)

      assert {:ok, ^path} = ByCrawl.find_path(start_url, core_url)
    end


    test "should except extend path error" do
      path = gen_urls(7)
      core_url = List.last(path)
      start_url = List.first(path)

      heading_path = Enum.take(path, 3)
      inter_url = Enum.at(path, 4)

      streamed_path = heading_path ++ [inter_url]

      {streamed, _} =
        Enum.reduce(
          Enum.drop(streamed_path, 1),
          {[], start_url},
          fn sub, {acc, abv} ->
            {acc ++ [{:ok, abv, sub}], sub}
          end
        )

      expect(CrawlerMock, :crawl, fn ^start_url -> streamed end)

      stub(
        WikiURLMock,
        :canonical?,
        fn
          ^core_url, ^core_url -> true
          _, _ -> false
        end
      )

      stub(PathsMock, :register_path, fn _path -> :ok end)

      stub(PathsMock, :registered_url?, fn
        ^inter_url -> true
        _url -> false
      end)

      expect(PathsMock, :extend_path, fn ^streamed_path, ^core_url ->
        {:error, :not_found}
      end)

      assert {:error, %NotFoundPathError{}} = ByCrawl.find_path(start_url, core_url)
    end
  end
end
