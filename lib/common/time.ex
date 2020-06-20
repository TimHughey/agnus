defmodule Agnus.Time.Helper do
  @moduledoc false
  use Timex

  @doc """
    Converts a Timex.shift/2 list of opts to milliseconds
  """
  @doc since: "0.0.3"
  def list_to_ms(opts, defaults) do
    # after hours of searching and not finding an existing capabiility
    # in Timex we'll roll our own consisting of multiple Timex functions.

    actual_opts =
      cond do
        valid_duration_opts?(opts) -> opts
        valid_duration_opts?(defaults) -> defaults
        true -> [minutes: 1]
      end

    ~U[0000-01-01 00:00:00Z]
    |> Timex.shift(duration_opts(actual_opts))
    |> Timex.to_gregorian_microseconds()
    |> Duration.from_microseconds()
    |> Duration.to_milliseconds(truncate: true)
  end

  @doc """
    Returns a DateTime representing now in UTC timezone
  """
  @doc since: "0.0.3"
  def utc_now do
    Timex.now()
  end

  ##
  ## PRIVATE
  ##

  defp duration_opts(opts) do
    case opts do
      [o] when is_nil(o) ->
        []

      o when is_list(o) ->
        Keyword.take(o, [
          :microseconds,
          :seconds,
          :minutes,
          :hours,
          :days,
          :weeks,
          :months,
          :years
        ])

      _o ->
        []
    end
  end

  defp valid_duration_opts?(opts) do
    # attempt to handle whatever is passed us by wrapping in a list and flattening
    opts = [opts] |> List.flatten()

    case duration_opts(opts) do
      [x] when is_nil(x) -> false
      x when x == [] -> false
      _x -> true
    end
  end
end
