defmodule OhMyAdolf.Wiki.CrawlerTest do
  use ExUnit.Case, async: true
  import Mox

  alias OhMyAdolf.Wiki.Crawler
  alias OhMyAdolf.Wiki.ScraperMock

  describe "Crawler crawl/2" do
    test "should scrape the start point" do
      start_url = URI.parse("http://host.foo/path")

      expect(ScraperMock, :scrape, fn ^start_url -> {:ok, []} end)
      Crawler.crawl(start_url)
    end

    test "should emit scraped the start point" do
      start_url = URI.parse("http://host.foo/path")
      sub_url = URI.parse("http://host.foo/path/a")

      expect(ScraperMock, :scrape, 1 + 1, fn
        ^start_url -> {:ok, [sub_url]}
        ^sub_url -> {:ok, []}
      end)

      assert [{:ok, ^start_url, ^sub_url}] =
               Crawler.crawl(start_url) |> Enum.to_list()
    end

    test "should emit errored scrape of the start point" do
      start_url = URI.parse("http://host.foo/path")
      reason = "mega reason"

      expect(ScraperMock, :scrape, fn ^start_url -> {:error, reason} end)

      assert [{:error, ^reason, ^start_url}] =
               Crawler.crawl(start_url) |> Enum.to_list()
    end

    test "should emit scraped sub urls" do
      start_url = URI.parse("http://host.foo/path")

      sub_urls = gen_urls(10)

      expect(ScraperMock, :scrape, 1 + 10, fn
        ^start_url -> {:ok, sub_urls}
        _sub_url -> {:ok, []}
      end)

      exp = Enum.map(sub_urls, &{:ok, start_url, &1})
      result = Crawler.crawl(start_url) |> Enum.to_list()

      assert ^exp = result
    end

    test "should emit errored sub url" do
      start_url = URI.parse("http://host.foo/path")
      sub_urls = gen_urls(8)
      errored_sub_url = Enum.at(sub_urls, 5)
      reason = "mega reason"

      expect(ScraperMock, :scrape, 1 + 8, fn
        ^start_url -> {:ok, sub_urls}
        ^errored_sub_url -> {:error, reason}
        _sub_url -> {:ok, []}
      end)

      result = Crawler.crawl(start_url) |> Enum.to_list()

      scraped_sub_urls =
        result
        |> Enum.filter(fn
          {:error, ^reason, ^errored_sub_url} -> false
          _ -> true
        end)

      # check if there is the errored sub url
      assert Enum.member?(result, {:error, reason, errored_sub_url})

      # check if there are only known and not duplicated urls
      # scraping one of the urls was errored and it was emitted too
      assert length(Enum.uniq(result)) === length(sub_urls) + 1

      assert Enum.all?(scraped_sub_urls, fn
               {:ok, _url, sub_url} -> Enum.member?(sub_urls, sub_url)
             end)
    end
  end

  defp gen_urls(total) do
    for i <- 1..total, do: URI.parse("https://a.a/a-#{i}")
  end
end
