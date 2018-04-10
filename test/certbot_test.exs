defmodule CertbotTest do
  use ExUnit.Case
  doctest Certbot

  test "greets the world" do
    assert Certbot.hello() == :world
  end
end
