defmodule OhMyAdolf.Wiki.FetcherTest do
  use ExUnit.Case, async: true
  import Mox

  alias OhMyAdolf.Wiki.Fetcher
  alias OhMyAdolf.HTTPClientMock

  alias OhMyAdolf.Wiki.{BadResponseError, BadRequestError}

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

  describe "Wiki.Fetcher fetch_page/1" do
    test "should extract page on 200 status code" do
      url = URI.parse("http://host.foo/path")
      url_str = URI.to_string(url)
      body = "apples"

      expect(HTTPClientMock, :get, fn ^url_str, _headers, _options ->
        {:ok, %HTTPoison.Response{status_code: 200, body: body}}
      end)

      assert {:ok, ^body} = Fetcher.fetch_page(url)
    end

    test "should except non-200 status code" do
      url = URI.parse("http://host.foo/path")
      url_str = URI.to_string(url)

      status_codes = [100, 201, 203, 404, 500]

      for status <- status_codes do
        expect(HTTPClientMock, :get, fn ^url_str, _headers, _options ->
          {:ok, %HTTPoison.Response{status_code: status, body: "body"}}
        end)

        assert {:error, %BadResponseError{url: ^url, status_code: ^status}} = Fetcher.fetch_page(url)
      end
    end

    test "should except httpoison error" do
      url = URI.parse("http://host.foo/path")
      url_str = URI.to_string(url)
      reason = :timeout

      expect(HTTPClientMock, :get, fn ^url_str, _headers, _options ->
        {:error, %HTTPoison.Error{reason: reason}}
      end)

      assert {:error, %BadRequestError{url: ^url, reason: ^reason}} = Fetcher.fetch_page(url)
    end
  end
end
