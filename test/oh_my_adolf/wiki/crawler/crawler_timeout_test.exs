defmodule OhMyAdolf.Wiki.CrawlerTimeoutTest do
  use ExUnit.Case, async: true
  import Mox

  alias OhMyAdolf.Wiki.Crawler
  alias OhMyAdolf.Wiki.ScraperMock

  @timeout Application.compile_env!(:oh_my_adolf, [:wiki, :scraping_timeout])

  describe "Crawler crawl/2" do
    test "should emit scraping timeout of the start point" do
      start_url = URI.parse("http://host.foo/path")

      expect(ScraperMock, :scrape, 2, fn ^start_url ->
        Process.sleep(@timeout + 1000)
      end)

      assert [{:error, :timeout, ^start_url}] =
               Crawler.crawl(start_url) |> Enum.to_list()
    end

    test "should skip sub url that exceeded timeout" do
      start_url = URI.parse("http://host.foo/path")
      sub_urls = gen_urls(8)
      exceeded_sub_url = Enum.at(sub_urls, 5)

      expect(ScraperMock, :scrape, 1 + 8, fn
        ^start_url ->
          {:ok, sub_urls}

        ^exceeded_sub_url ->
          Process.sleep(@timeout + 1000)

        _sub_url ->
          {:ok, []}
      end)

      result = Crawler.crawl(start_url) |> Enum.to_list()

      # check if there are only known and not duplicated urls
      # one of the urls exceeded the timeout and it was skipped
      assert length(Enum.uniq(result)) === length(sub_urls)

      # check if there are only known sub urls
      assert Enum.all?(result, fn
               {:ok, ^start_url, sub_url} -> Enum.member?(sub_urls, sub_url)
             end)
    end
  end

  defp gen_urls(total) do
    for i <- 1..total, do: URI.parse("https://a.a/a-#{i}")
  end
end
