defmodule OhMyAdolf.Wiki.FetcherTest do
  use ExUnit.Case, async: true
  import Mox

  alias OhMyAdolf.Wiki.Fetcher
  alias OhMyAdolf.HTTPClientMock

  @options Application.compile_env!(:oh_my_adolf, [:wiki, :http_options])
  @headers Application.compile_env!(:oh_my_adolf, [:wiki, :http_headers])

  describe "Wiki.Fetcher fetch/1" do
    test "should request using the provided but stringified url" do
      url = URI.parse("http://host.foo/path")
      url_str = URI.to_string(url)

      expect(HTTPClientMock, :get, fn ^url_str, _headers, _options ->
        {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
      end)

      Fetcher.fetch(url)
    end

    test "should request using the configured headers" do
      url = URI.parse("http://host.foo/path")
      headers = @headers

      expect(HTTPClientMock, :get, fn _url, ^headers, _options ->
        {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
      end)

      Fetcher.fetch(url)
    end

    test "should request using the configured options" do
      url = URI.parse("http://host.foo/path")
      options = @options

      expect(HTTPClientMock, :get, fn _url, _headers, ^options ->
        {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
      end)

      Fetcher.fetch(url)
    end
  end
end
