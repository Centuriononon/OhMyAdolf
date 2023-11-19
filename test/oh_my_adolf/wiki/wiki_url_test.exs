defmodule OhMyAdolf.Wiki.WikiURLTest do
  use ExUnit.Case, async: true
  alias OhMyAdolf.Wiki.WikiURL
  alias OhMyAdolf.Wiki.Errors.InvalidURLError

  @host Application.compile_env!(:oh_my_adolf, [:wiki, :host])

  describe "Wiki.WikiURL validate_url/1" do
    test "should pass root url" do
      url = %URI{host: @host, scheme: "http"}
      assert {:ok, ^url} = WikiURL.validate_url(url)
    end

    test "should pass https scheme" do
      url = %URI{host: @host, scheme: "https"}
      assert {:ok, ^url} = WikiURL.validate_url(url)
    end

    test "should pass one and only one wiki url host" do
      hosts = ~w(wikipedia.org en.wikipedia.org)
      host = Enum.find(hosts, &(&1 !== @host))

      url = %URI{host: host, scheme: "http"}
      assert {:error, %InvalidURLError{}} = WikiURL.validate_url(url)
    end

    test "should not change provided URI" do
      url = %URI{host: @host, scheme: "http"}
      assert {:ok, ^url} = WikiURL.validate_url(url)
    end

    test "should pass url with an arbitrary path" do
      url = URI.parse("http://" <> @host <> "/kokG/koko")
      assert {:ok, ^url} = WikiURL.validate_url(url)
    end

    test "should pass url with arbitrary query string" do
      url = URI.parse("http://" <> @host <> "?id=1&h=fd")
      assert {:ok, ^url} = WikiURL.validate_url(url)
    end

    test "should not pass url with invalid host" do
      invalid_url = %URI{host: @host <> ".x", scheme: "http"}
      assert {:error, _reason} = WikiURL.validate_url(invalid_url)
    end

    test "should not pass url with invalid scheme" do
      invalid_url = %URI{host: @host <> ".x", scheme: "http"}
      assert {:error, _reason} = WikiURL.validate_url(invalid_url)
    end

    test "should return specific error exception" do
      invalid_url = %URI{host: @host <> ".x", scheme: "http"}

      assert {:error, %InvalidURLError{message: "Invalid or unsupported url"}} =
               WikiURL.validate_url(invalid_url)
    end
  end

  describe "Wiki.WikiURL valid_url?/1" do
    test "should return ture on https scheme" do
      url = %URI{host: @host, scheme: "https"}
      assert true = WikiURL.valid_url?(url)
    end

    test "should return true on root url" do
      url = %URI{host: @host, scheme: "http"}
      assert true = WikiURL.valid_url?(url)
    end

    test "should return true on url with arbitrary query string" do
      url = URI.parse("https://" <> @host <> "?a=43&b=fddf")
      assert true = WikiURL.valid_url?(url)
    end

    test "should return true on url with an arbitrary path " do
      url = URI.parse("http://" <> @host <> "/R/u/o")
      assert true = WikiURL.valid_url?(url)
    end

    test "should return false on invalid host" do
      invalid_url = %URI{host: @host <> ".x", scheme: "http"}
      assert false === WikiURL.valid_url?(invalid_url)
    end

    test "should return false on invalid scheme" do
      invalid_url = %URI{host: @host, scheme: "ws"}
      assert false === WikiURL.valid_url?(invalid_url)
    end
  end

  describe "Wiki.WikiURL valid_host?/1" do
    test "should return true on valid host" do
      assert true = WikiURL.valid_host?(@host)
    end

    test "should return false on invalid host" do
      dummy_host = @host <> ".x"
      assert false === WikiURL.valid_host?(dummy_host)
    end
  end

  describe "Wiki.WikiURL valid_scheme?/1" do
    test "should pass http scheme" do
      assert true = WikiURL.valid_scheme?("http")
    end

    test "should not https scheme" do
      assert true = WikiURL.valid_scheme?("https")
    end

    test "should not pass invalid scheme" do
      assert false === WikiURL.valid_scheme?("ws")
    end
  end

  describe "Wiki.WikiURL absolute_url/1" do
    test "should parse arbitrary path as URI" do
      assert %URI{} = WikiURL.absolute_url("/fd/fa---f/fds")
    end

    test "should absolute path as valid url" do
      assert %URI{} = url = WikiURL.absolute_url("/fhaksl/f/32fdsa")
      assert WikiURL.valid_url?(url)
    end

    test "should absolute query string as valid url" do
      assert %URI{} = url = WikiURL.absolute_url("?a=bc=32452")
      assert WikiURL.valid_url?(url)
    end

    test "should not absolute path if it is already absolute url" do
      url = "https://ny.wikipedia.org/wiki/Adolf_Hitler"
      assert ^url = url |> WikiURL.absolute_url() |> URI.to_string()
    end
  end

  describe "Wiki.WikiURL downcase/1" do
    test "should return URI" do
      uri = URI.parse("/fafda")
      assert %URI{} = WikiURL.downcase(uri)
    end

    test "should return downcased url" do
      url_str = "htTps://hosT.t/fho.faFd/faf/FFFFda"

      assert %URI{} = url = WikiURL.downcase(URI.parse(url_str))
      assert URI.to_string(url) === String.downcase(url_str)
    end
  end

  describe "Wiki.WikiURL canonical?/2" do
    test "should return true on provided the same urls" do
      url = WikiURL.absolute_url("/wiki")
      assert true = WikiURL.canonical?(url, url)
    end

    test "should return true on urls with different case" do
      url_1 = WikiURL.absolute_url("/A/b/C/e")
      url_2 = WikiURL.absolute_url("/a/B/c/E")

      assert true = WikiURL.canonical?(url_1, url_2)
    end

    test "should return false on differenct urls" do
      url_1 = WikiURL.absolute_url("/A/b/C")
      url_2 = WikiURL.absolute_url("/1/2/3")

      assert false === WikiURL.canonical?(url_1, url_2)
    end
  end

  describe "Wiki.WikiURL absolute_url?/1" do
    test "should return true if url is completely absolute" do
      url = URI.parse("https://wikipedia.org/wiki")
      assert true = WikiURL.absolute_url?(url)
    end

    test "should return false if url missing scheme" do
      uri = URI.parse("wikipedia.org/wiki")
      assert false === WikiURL.absolute_url?(uri)
    end

    test "should return false if uri with path only" do
      uri = URI.parse("/wiki")
      assert false === WikiURL.absolute_url?(uri)
    end
  end
end
