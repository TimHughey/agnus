defmodule Agnus.MixProject do
  use Mix.Project

  def project do
    [
      app: :agnus,
      version: "0.0.2",
      elixir: "~> 1.10",
      description: "Agnus",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      releases: releases(),
      package: package(),
      homepage_url: "https://www.wisslanding.com",
      source_url: "https://github.com/TimHughey/agnus"
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

  defp deps,
    do: [
      {:timex, "~> 3.0"},
      {:jason, "~> 1.0"},
      {:httpoison, "~> 1.6"},
      {:credo, "> 0.0.0", only: [:dev, :test], runtime: false},
      {:coverex, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]

  defp docs,
    do: [
      main: "api-reference.html#modules",
      extras: ["CHANGELOG.md"]
    ]

  defp releases,
    do: [
      agnus: [
        include_erts: true,
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent],
        cookie: "augury-kinship-swain-circus",
        steps: [:assemble, :tar]
      ]
    ]

  defp package,
    do: [
      name: "agnus",
      files: ~w(lib test
            .credo.exs .formatter.exs mix.exs
            COPYING* README* LICENSE* CHANGELOG*),
      links: %{"GitHub" => "https://github.com/TimHughey/agnus"},
      maintainers: ["Tim Hughey"],
      licenses: ["LGPL-3.0-or-later"]
    ]
end
