defmodule OhMyAdolf.Wiki.ParserTest do
  use ExUnit.Case, async: true
  import Mox

  alias OhMyAdolf.Wiki.Parser
  alias OhMyAdolf.Wiki.WikiURLMock

  describe "Wiki.Parser extract_wiki_urls/2" do
    test "should extract relative paths from the body content only" do
      to_skip = ["/wiki/apple", "/wiki/banana", "/wiki/pineapple"]
      to_collect = ["/wiki/one", "/wiki/two", "/wiki/three"]

      html = """
      <html>
        <body>
          <header class="vector-header mw-header">
            <a href="#{Enum.at(to_skip, 0)}"></a>
          </header>
          <main>
            <header>
              <a href="#{Enum.at(to_skip, 1)}"></a>
            </header>
            <div id="bodyContent">
              <a href="#{Enum.at(to_collect, 0)}"></a>
              <a href="#{Enum.at(to_collect, 1)}"></a>
              <a href="#{Enum.at(to_collect, 2)}"></a>
            </div>
          </main>
          <footer id="footer" class="mw-footer" role="contentinfo">
            <a href="#{Enum.at(to_skip, 2)}"></a>
          </footer>
        </body>
      </html>
      """

      stub(WikiURLMock, :absolute_url, &URI.parse/1)
      stub(WikiURLMock, :downcase, fn %URI{} = u -> u end)
      stub(WikiURLMock, :valid_url?, fn %URI{} -> true end)

      {:ok, urls} = Parser.extract_wiki_urls(html)
      urls = Enum.to_list(urls)

      assert length(urls) === length(to_collect)
      assert Enum.all?(urls, &Enum.member?(to_collect, &1.path))
    end

    test "should absolute extracted relative paths" do
      to_collect = ["/wiki/one", "/wiki/two", "/wiki/three"]

      html = """
      <html>
        <body>
          <main>
            <div id="bodyContent">
            <a href="#{Enum.at(to_collect, 0)}"></a>
            <a href="#{Enum.at(to_collect, 1)}"></a>
            <a href="#{Enum.at(to_collect, 2)}"></a>
            </div>
          </main>
        </body>
      </html>
      """

      host_stamp = "absoluted"

      stub(WikiURLMock, :absolute_url, &%URI{host: host_stamp, path: &1})
      stub(WikiURLMock, :downcase, & &1)
      stub(WikiURLMock, :valid_url?, fn _ -> true end)

      {:ok, urls} = Parser.extract_wiki_urls(html)
      urls = Enum.to_list(urls)

      assert length(urls) === length(to_collect)
      assert Enum.all?(urls, &(&1.host === host_stamp))
    end

    test "should downcase urls" do
      to_collect = ["/wiki/one", "/wiki/two", "/wiki/three"]

      html = """
      <html>
        <body>
          <main>
            <div id="bodyContent">
            <a href="#{Enum.at(to_collect, 0)}"></a>
            <a href="#{Enum.at(to_collect, 1)}"></a>
            <a href="#{Enum.at(to_collect, 2)}"></a>
            </div>
          </main>
        </body>
      </html>
      """

      host_stamp = "downcased"

      stub(WikiURLMock, :absolute_url, &URI.parse/1)

      stub(WikiURLMock, :downcase, fn %URI{path: path} ->
        %URI{path: path, host: host_stamp}
      end)

      stub(WikiURLMock, :valid_url?, fn _ -> true end)

      {:ok, urls} = Parser.extract_wiki_urls(html)
      urls = Enum.to_list(urls)

      assert length(urls) === length(to_collect)
      assert Enum.all?(urls, &(&1.host === host_stamp))
    end

    test "should check url validity" do
      valid_path = "/valid"
      invalid_path = "/invalid"
      to_skip = [invalid_path, invalid_path]
      to_collect = [valid_path, valid_path, valid_path]

      html = """
      <html>
        <body>
          <main>
            <div id="bodyContent">
            <a href="#{Enum.at(to_collect, 0)}"></a>
            <a href="#{Enum.at(to_skip, 0)}"></a>
            <a href="#{Enum.at(to_collect, 1)}"></a>
            <a href="#{Enum.at(to_collect, 2)}"></a>
            <a href="#{Enum.at(to_skip, 1)}"></a>
            </div>
          </main>
        </body>
      </html>
      """

      stub(WikiURLMock, :absolute_url, &URI.parse/1)

      stub(WikiURLMock, :downcase, & &1)

      stub(WikiURLMock, :valid_url?, fn
        %URI{path: ^valid_path} -> true
        %URI{path: ^invalid_path} -> false
      end)

      {:ok, urls} = Parser.extract_wiki_urls(html)

      urls = Enum.to_list(urls)

      assert length(urls) === length(to_collect)
      assert Enum.all?(urls, &Enum.member?(to_collect, &1.path))
    end

    test "should exclude urls" do
      to_collect = ["/wiki/one", "/wiki/two", "/wiki/three"]
      to_exclude = ["/wiki/apple", "/wiki/banana"]

      html = """
      <html>
        <body>
          <main>
            <div id="bodyContent">
              <a href="#{Enum.at(to_collect, 0)}"></a>
              <a href="#{Enum.at(to_exclude, 0)}"></a>
              <a href="#{Enum.at(to_collect, 1)}"></a>
              <a href="#{Enum.at(to_exclude, 1)}"></a>
              <a href="#{Enum.at(to_collect, 2)}"></a>
            </div>
          </main>
        </body>
      </html>
      """

      stub(WikiURLMock, :absolute_url, &URI.parse/1)
      stub(WikiURLMock, :downcase, & &1)
      stub(WikiURLMock, :valid_url?, fn _ -> true end)

      stub(WikiURLMock, :canonical?, fn uri_1, uri_2 ->
        uri_1.path === uri_2.path
      end)

      urls_to_exclude = to_exclude |> Enum.map(&URI.parse/1)

      {:ok, urls} = Parser.extract_wiki_urls(html, exclude: urls_to_exclude)
      urls = Enum.to_list(urls)

      assert length(urls) === length(to_collect)
      assert Enum.all?(urls, &Enum.member?(to_collect, &1.path))
    end
  end
end
