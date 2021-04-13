defmodule Agnus do
  @moduledoc """
  Agnus is an Elixir supervised GenServer wrapping [Sunrise Sunset](https://sunrise-sunset.org)
  """

  alias Agnus.{Server, Types}

  @doc """
  Is the data available for today?

  ## Examples

      iex> Agnus.current?()
      iex> true

  """
  @doc since: "0.0.3"
  @spec current?() :: true | false
  def current?, do: call({:current?, []}, 100)

  @doc """
  Get all or some sun information for today

  ## Examples

      iex> info = Agnus.sun_info(:all)
      iex> is_map(info)
      true

      iex> info = Agnus.sun_info(:astronomical_twilight_begin)
      iex> DateTime.diff(info, info)
      0

      iex> info = Agnus.sun_info(:astronomical_twilight_end)
      iex> DateTime.diff(info, info)
      0

      iex> info = Agnus.sun_info(:day_length)
      iex> is_integer(info)
      true

      iex> info = Agnus.sun_info([:astronomical_twilight_begin, :astronomical_twilight_end])
      iex> is_map(info)
      true
      iex> Enum.count(info)
      2

  """
  @doc since: "0.0.3"
  @spec sun_info(Types.suninfo_request()) :: Types.suninfo_response()

  def sun_info(term \\ :all) do
    Server.get_info(term)
  end

  @doc """
  Get the sun info keys available

  ## Examples

      iex> keys = Agnus.keys()
      iex> :sunrise in keys
      true
      iex> :sunset in keys
      true
      iex> Enum.count(keys)
      11

  """
  @doc since: "0.0.3"
  @spec keys() :: [Types.suninfo_key()]
  def keys, do: Server.get_info(:keys)

  @doc """
  Get noon

  ## Examples

      iex> noon = Agnus.noon()
      iex> DateTime.diff(noon, noon)
      0

  """
  @doc since: "0.0.3"
  @spec noon() :: DateTime.t()
  def noon, do: Server.get_info(:solar_noon)

  @doc """
  Get sunrise

  ## Examples

      iex> sunrise = Agnus.sunrise()
      iex> DateTime.diff(sunrise, sunrise)
      0

  """
  @doc since: "0.0.3"
  @spec sunrise() :: DateTime.t()
  def sunrise, do: Server.get_info(:sunrise)

  @doc """
  Get sunset

  ## Examples

      iex> sunset = Agnus.sunset()
      iex> DateTime.diff(sunset, sunset)
      0

  """
  @doc since: "0.0.3"
  @spec sunset() :: DateTime.t()
  def sunset, do: Server.get_info(:sunset)

  @doc """
  Trigger a refresh of the sun info for today

  > The most recent data is cached and, as such, repeated calls to this function
  > on the same day are no ops.

  ## Examples

      iex> Agnus.trigger_refresh()
      :ok

      iex> Agnus.trigger_refresh(force: true)
      :ok

  """
  @doc since: "0.1.1"
  @spec trigger_sun_info_refresh(Types.trigger_opts()) :: :ok
  def trigger_refresh(opts \\ [force: false]) when is_list(opts),
    do: cast({:action, :day_refresh, opts})

  @doc """
  Trigger a refresh of the sun info for today

  > The most recent data is cached and, as such, repeated calls to this function
  > on the same day are no ops.

  ## Examples

      iex> Agnus.trigger_sun_info_refresh()
      :ok

      iex> Agnus.trigger_sun_info_refresh(force: true)
      :ok

  """
  @doc since: "0.0.3"
  @deprecated "Use trigger_refresh/1 instead"
  defdelegate trigger_sun_info_refresh(opts \\ [force: false]), to: Agnus, as: :trigger_refresh

  @doc """
  Enable or disable caching of the JSON response from [Sunrise Sunset](https://sunrise-sunset.org)

  ## Examples

      iex> Agnus.cache_json("/tmp/agnus.json")
      "/tmp/agnus.json"

      iex> Agnus.cache_json(:none)
      :none

      iex> cf = Agnus.cache_json(:query)
      iex> is_binary(cf) or cf == :none
      true

  """
  @doc since: "0.1.1"
  @spec cache_json(Types.cache_file()) :: Types.cache_file()
  def cache_json(cache_file \\ :query)
      when is_binary(cache_file) or cache_file in [:none, :query] do
    call({:action, :cache_file, cache_file})
  end

  @doc false
  defdelegate get_info(what), to: Server

  @doc false
  def call(msg, timeout \\ 1000), do: GenServer.call(Server, msg, timeout)

  @doc false
  def cast(msg), do: GenServer.cast(Server, msg)
end
