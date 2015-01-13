defmodule Slugmenu.Mixfile do
  use Mix.Project

  def project do
    [app: :slugmenu,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :pipe],
      mod: {Slugmenu, []}]
  end

  defp deps do
    [{:pipe, github: "batate/elixir-pipes"}]
  end
end
