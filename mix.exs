defmodule Slugmenu.Mixfile do
  use Mix.Project

  def project do
    {opts, _argv, _errors} = OptionParser.parse(System.argv(), strict: [port: :number], aliases: [p: :port])
    port = case opts[:port] do
      nil -> "8080"
      x -> x
    end
    [app: :slugmenu,
      version: "0.0.1",
      elixir: "~> 1.0",
      deps: deps,
      port: port
    ]
  end

  defp deps do
    [{:pipe, github: "batate/elixir-pipes"},
      {:urna, github: "meh/urna"},
      {:httpoison, "~> 0.5"},
      {:floki, "~> 0.1.0"},
      {:timex, "~> 0.13.3"}
    ]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:logger, :pipe],
      mod: {Slugmenu, []}
    ]
  end
end
