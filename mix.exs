defmodule Agnus.MixProject do
  use Mix.Project

  def project do
    [
      app: :agnus,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Agnus.Application, []},
      env: [
        day_info: [
          log: [init: false, init_args: false],
          tz: "America/New_York",
          api: [
            url: "https://api.sunrise-sunset.org",
            lat: 40.2108,
            lng: -74.011
          ]
        ]
      ]
    ]
  end

  defp deps do
    [
      {:timex, "~> 3.0"},
      {:jason, "~> 1.0"},
      {:httpoison, "~> 1.6"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp releases do
    [
      agnus: [
        include_erts: true,
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent],
        cookie: "augury-kinship-swain-circus",
        steps: [:assemble, :tar]
      ]
    ]
  end
end
