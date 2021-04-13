defmodule Agnus.Parser do
  @moduledoc false

  use Timex

  @doc false
  def convert_datetimes(raw, %{opts: %{tz: tz}}) do
    {:convert,
     for {k, v} <- raw, reduce: %{} do
       acc ->
         case Timex.parse(v, "{ISO:Extended}") do
           # a valid datetime, keep it
           {:ok, dt} -> put_in(acc, [k], Timex.to_datetime(dt, tz))
           # a pure integer (e.g. day_length)
           {:error, :badarg} when is_integer(v) -> put_in(acc, [k], v)
           # not interested, skip it
           _nomatch -> acc
         end
     end}
  end

  @doc false
  def decode(%{body: body} = s) do
    with {:ok, %{results: results, status: "OK"}} <- Jason.decode(body, keys: :atoms),
         # convert the resulting DateTimes to the configured timezone
         {:convert, parsed} when is_map(parsed) <- convert_datetimes(results, s),
         # is the decoded datetimes for today?
         {parsed, :current} <- for_today?(parsed, s) do
      # all is well
      put_in(s, [:parsed], parsed)
    else
      {_latest, :stale} ->
        put_in(s, [:need_fetch], true)

      error ->
        put_in(s, [:error], error)
    end
  end

  def for_today?(%{sunrise: sunrise} = parsed, %{opts: %{tz: tz}}) do
    now = Timex.now(tz)

    if Timex.day(now) == Timex.day(sunrise),
      do: {parsed, :current},
      else: {parsed, :stale}
  end
end
