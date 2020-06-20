defmodule Agnus do
  @moduledoc """
  `Agnus` is [Sunrise Sunset](https://sunrise-sunset.org) wrapped in an Elixir supervised GenServer.
  """

  @doc delegate_to: {Agnus.DayInfo, :current?, 0}
  defdelegate current?, to: Agnus.DayInfo

  @doc delegate_to: {Agnus.DayInfo, :sun_info, 1}
  defdelegate sun_info(term), to: Agnus.DayInfo, as: :get_info

  @doc delegate_to: {Agnus.DayInfo, :keys, 0}
  defdelegate keys, to: Agnus.DayInfo

  @doc delegate_to: {Agnus.DayInfo, :trigger_day_info_refresh, 0}
  defdelegate trigger_sun_info_refresh, to: Agnus.DayInfo, as: :trigger_day_info_refresh

  @doc delegate_to: {Agnus.DayInfo, :noon, 0}
  defdelegate noon, to: Agnus.DayInfo

  @doc delegate_to: {Agnus.DayInfo, :sunrise, 0}
  defdelegate sunrise, to: Agnus.DayInfo

  @doc delegate_to: {Agnus.DayInfo, :sunset, 0}
  defdelegate sunset, to: Agnus.DayInfo
end
