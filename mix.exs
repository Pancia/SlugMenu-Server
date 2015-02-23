defmodule Slugmenu.Mixfile do
  use Mix.Project

  def project do
    {opts, _argv, _errors} = OptionParser.parse(System.argv(), strict: [port: :number], aliases: [p: :port])
    [app: :slugmenu,
      version: "0.0.1",
      elixir: "~> 1.0",
      deps: deps,
      port: opts[:port]
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :pipe],
      mod: {Slugmenu, []}
    ]
  end

  defp deps do
    [{:pipe, github: "batate/elixir-pipes"},
      {:urna, github: "meh/urna"},
      {:httpoison, "~> 0.5"}
    ]
  end
end
