defmodule Agnus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Application, only: [get_env: 2]

    children = [
      {Agnus.DayInfo, get_env(:agnus, :day_info)}
      # Starts a worker by calling: Agnus.Worker.start_link(arg)
      # {Agnus.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Agnus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
