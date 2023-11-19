defmodule OhMyAdolf.Wiki.ScraperTest do
  use ExUnit.Case, async: true
  import Mox

  alias OhMyAdolf.Wiki.Scraper
  alias OhMyAdolf.Wiki.ParserMock
  alias OhMyAdolf.Wiki.FetcherMock

  describe "Wiki.Scraper scrape/1" do
    test "should fetch page by provided url" do
      url = URI.parse("http://host.ho/path")

      expect(FetcherMock, :fetch_page, fn ^url -> {:ok, ""} end)
      stub(ParserMock, :extract_wiki_urls, fn _, _ -> {:ok, []} end)

      assert {:ok, _} = Scraper.scrape(url)
    end

    test "should parse fetched page" do
      page = "<html>Hi</html>"

      expect(FetcherMock, :fetch_page, fn _ -> {:ok, page} end)
      stub(ParserMock, :extract_wiki_urls, fn ^page, _ -> {:ok, []} end)

      assert {:ok, _} = Scraper.scrape(%URI{})
    end

    test "should return sub urls" do
      url = URI.parse("http://host.ho/path")
      sub_url = URI.parse("http://host.ho/pathpath")

      expect(FetcherMock, :fetch_page, fn ^url -> {:ok, ""} end)
      stub(ParserMock, :extract_wiki_urls, fn _, _ -> {:ok, [sub_url]} end)

      assert {:ok, [^sub_url]} = Scraper.scrape(url)
    end

    test "should exclude provded url" do
      url = URI.parse("http://host.ho/path")

      expect(FetcherMock, :fetch_page, fn ^url -> {:ok, ""} end)

      stub(ParserMock, :extract_wiki_urls, fn _, exclude: [^url] ->
        {:ok, []}
      end)

      assert {:ok, []} = Scraper.scrape(url)
    end

    test "should return either on fetch error" do
      error = {:error, "fetch fail"}

      stub(FetcherMock, :fetch_page, fn _ -> error end)

      assert ^error = Scraper.scrape(%URI{})
    end

    test "should return either on parse error" do
      error = {:error, "parse fail"}

      stub(FetcherMock, :fetch_page, fn _ -> {:ok, ""} end)
      stub(ParserMock, :extract_wiki_urls, fn _, _ -> error end)

      assert ^error = Scraper.scrape(%URI{})
    end
  end
end
