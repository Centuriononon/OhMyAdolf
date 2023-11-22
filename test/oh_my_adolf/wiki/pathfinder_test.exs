defmodule OhMyAdolf.Wiki.PathfinderTest do
  use ExUnit.Case, async: true

  import Mox
  alias OhMyAdolf.Wiki.Pathfinder

  alias OhMyAdolf.Wiki.Pathfinder.ByCrawlMock
  alias OhMyAdolf.Wiki.PathsMock
  alias OhMyAdolf.Wiki.WikiURLMock

  describe "Wiki.Pathfinder find_path/2" do
    test "should downcase the start and core urls by default" do
      start_url = URI.parse("http://host/start")
      core_url = URI.parse("http://host/core")

      expect(WikiURLMock, :downcase, fn ^start_url -> start_url end)
      expect(WikiURLMock, :downcase, fn ^core_url -> core_url end)

      stub(WikiURLMock, :canonical?, fn _, _ -> true end)

      Pathfinder.find_path(start_url, core_url)
    end

    test "should return the core url if provided the path already" do
      start_url = URI.parse("http://host/start")
      core_url = URI.parse("http://host/core")

      stub(WikiURLMock, :downcase, fn url -> url end)

      expect(WikiURLMock, :canonical?, fn ^start_url, ^core_url -> true end)

      assert {:ok, [^core_url]} = Pathfinder.find_path(start_url, core_url)
    end

    test "should try to find and return persisted path before crawl" do
      start_url = URI.parse("http://host/start")
      core_url = URI.parse("http://host/core")

      path = [start_url, %URI{}, core_url]

      stub(WikiURLMock, :downcase, fn url -> url end)
      stub(WikiURLMock, :canonical?, fn _, _ -> false end)

      expect(PathsMock, :get_path, fn ^start_url, ^core_url -> {:ok, path} end)

      assert {:ok, ^path} = Pathfinder.find_path(start_url, core_url)
    end

    test "should delegate path finding to the pathfinder by crawl" do
      start_url = URI.parse("http://host/start")
      core_url = URI.parse("http://host/core")

      path = [start_url, %URI{}, core_url]

      stub(WikiURLMock, :downcase, fn url -> url end)
      stub(WikiURLMock, :canonical?, fn _url_1, _url_2 -> false end)
      stub(PathsMock, :get_path, fn _url_1, _url_2 -> {:error, :timeout} end)

      expect(ByCrawlMock, :find_path, fn ^start_url, ^core_url ->
        {:ok, path}
      end)

      assert {:ok, ^path} = Pathfinder.find_path(start_url, core_url)

      expect(ByCrawlMock, :find_path, fn ^start_url, ^core_url ->
        {:error, :not_found}
      end)

      assert {:error, :not_found} = Pathfinder.find_path(start_url, core_url)
    end
  end
end
