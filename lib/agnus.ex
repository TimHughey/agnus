defmodule Agnus do
  @moduledoc """
  `Agnus` is [Sunrise Sunset](https://sunrise-sunset.org) wrapped in an Elixir supervised GenServer.
  """

  @doc """
  Is the data available for today?

  ## Examples

      iex> Agnus.current?()
      iex> true

  """
  defdelegate current?, to: Agnus.DayInfo

  @doc """
  Get all or some sun information for today

  ## Examples

      iex> info = Agnus.sun_info(:all)
      iex> is_map(info)

      iex> info = Agnus.sun_info(:astronomical_twilight_begin)
      iex> Map.has_key?(info, :astronomical_twilight_begin)

      iex> info =
      ...>  Agnus.sun_info([:astronomical_twilight_begin, :astronomical_twilight_begin])
      iex> Map.has_key?(info, :astronomical_twilight_begin)
      iex> Map.has_key?(info, :astronomical_twilight_end)

  """
  defdelegate sun_info(term), to: Agnus.DayInfo, as: :get_info

  @doc """
  Get the sun info keys available

  ## Examples

      iex> keys = Agnus.keys()
      iex> [:sunrise, :sunset] in keys
      iex> Enum.count(keys) == 10

  """
  defdelegate keys, to: Agnus.DayInfo

  @doc """
  Trigger a refresh of the sun info for today

  ## Examples

      iex> :ok = Agnus.trigger_sun_info_refresh()

  > The most recent data is cached and, as such, repeated calls to this function
  > on the same day are no ops.

  """
  defdelegate trigger_sun_info_refresh, to: Agnus.DayInfo, as: :trigger_day_info_refresh
end
