defmodule Agnus.Opts do
  @moduledoc """
  Default opts unless otherwise configured in the application environment.

  **This module is documented for reference purposes only.**

  > As noted [elsewhere](docs/This Is Agnus.md), options not specified in the application environment will default
  > to the values in `defaults/0`
  """

  alias Agnus.Types

  @doc """
  Returns a map of the default options used by Agnus.

  ```elixir
  %{
    api: %{
      fetcher: Agnus.Fetcher,
      url: "https://api.sunrise-sunset.org",
      lat: 40.2108,
      lng: -74.011,
      timeout: 500,
      recv_timeout: 500
    },
    tz: "America/New_York",
    cache_file: :none,
    timeout: "PT1M",
    log: %{init: false, init_args: false, cache_failures: false}
  }
  ```
  """
  @doc since: "0.1.1"
  @spec defaults() :: Types.opts_map()
  def defaults do
    %{
      tz: "America/New_York",
      api: %{
        lat: 40.2108,
        lng: -74.011,
        url: "https://api.sunrise-sunset.org",
        fetcher: Agnus.Fetcher,
        timeout: 500,
        recv_timeout: 500
      },
      cache_file: :none,
      timeout: "PT1M",
      log: %{init: false, init_args: false, cache_failures: false}
    }
  end

  @doc false
  def put(state) do
    args = Application.get_env(:agnus, :day_info, [])

    merge_args(state, args)
  end

  @doc false
  def merge_args(state, args) do
    if Enum.empty?(args) do
      put_in(state, [:opts], defaults())
      |> put_in([:opts, :defaults], true)
    else
      def_log = get_in(defaults(), [:log])
      def_api = get_in(defaults(), [:api])

      args_log = Keyword.get(args, :log, %{}) |> Enum.into(%{})
      args_api = Keyword.get(args, :api, %{}) |> Enum.into(%{})

      base_keys = [:tz, :cache_file, :timeout]
      def_base = Map.take(defaults(), base_keys)
      args_base = Keyword.take(args, base_keys) |> Enum.into(%{})

      merged_base = Map.merge(def_base, args_base)
      merged_log = Map.merge(def_log, args_log)
      merged_api = Map.merge(def_api, args_api)

      final = put_in(merged_base, [:log], merged_log) |> put_in([:api], merged_api)

      put_in(state, [:opts], final)
    end
  end
end
