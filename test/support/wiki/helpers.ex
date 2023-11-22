defmodule OhMyAdolf.Test.Support.Wiki.Helpers do
  def gen_urls(n) do
    for i <- 1..n do
      URI.parse("http://host/#{i}")
    end
  end

  def gen_urls(from, n) do
    for i <- from..(from + n) do
      URI.parse("http://host/#{i}")
    end
  end
end
