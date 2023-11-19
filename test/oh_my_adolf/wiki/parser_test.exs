defmodule OhMyAdolf.Wiki.ParserTest do
  use ExUnit.Case, async: true
  alias OhMyAdolf.Wiki.Parser

  @wiki_url Application.compile_env(
              :oh_my_adolf,
              [:wiki, :wiki_url]
            )

  describe "Parser extract_wiki_urls/2 test" do
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

      assert
        html
        |> Parser.extract_wiki_urls(exclude: [])
        |> Enum.all?(&Enum.member?(to_collect, &1.path))
    end

    test "should extract relative url and absolute it" do
      html = """
      <html>
        <body>
          <main>
            <div id="bodyContent">
              <a href="/wiki/one"></a>
            </div>
          </main>
        </body>
      </html>
      """
    end
  end
end
