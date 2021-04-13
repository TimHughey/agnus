defmodule Agnus.MixProject do
  @moduledoc false

  use Mix.Project

  @version "0.1.2"

  def project do
    [
      app: :agnus,
      version: @version,
      elixir: "~> 1.8",
      description: "Agnus",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      releases: releases(),
      package: package(),
      source_url: "https://github.com/TimHughey/agnus",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Agnus.Application, []},
      env: [day_info: []]
    ]
  end

  defp deps,
    do: [
      {:timex, "~> 3.0"},
      {:jason, "~> 1.0"},
      {:httpoison, "~> 1.6"},
      {:credo, "> 0.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
    ]

  defp docs,
    do: [
      main: "this-is-agnus",
      formatter_opts: [gfm: true],
      source_ref: @version,
      source_url: "https://github.com/TimHughey/agnus",
      extras: [
        "docs/This Is Agnus.md",
        "docs/Basic Usage.md",
        "CHANGELOG.md"
      ]
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
