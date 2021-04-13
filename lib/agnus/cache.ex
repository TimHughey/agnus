defmodule Agnus.Cache do
  @moduledoc false

  require Logger

  alias Agnus.Parser

  def load_if_possible(%{nocache: true} = s), do: s

  def load_if_possible(%{opts: %{cache_file: cf, tz: tz, log: log_opts}} = s)
      when is_binary(cf) do
    case File.read(cf) do
      {:ok, body} ->
        Map.merge(s, %{body: body, last_fetch: Timex.now(tz)})
        |> Parser.decode()

      {:error, e} ->
        Map.get(log_opts, :cache_failures, false) &&
          Logger.warn(["read from cache ", cf, " failed: ", :file.format_error(e)])

        s
    end
  end

  def load_if_possible(s), do: s

  # never save if an error has occurred
  def save_if_needed(%{error: _} = s), do: s

  # save the document body if cache file is set and binary
  # no changes are made to state
  def save_if_needed(%{body: body, opts: %{cache_file: cf, log: log_opts}} = s)
      when is_binary(cf) do
    case File.write(cf, body) do
      :ok ->
        s

      {:error, e} ->
        Map.get(log_opts, :cache_failures, false) &&
          Logger.warn(["write to cache ", cf, " failed: ", :file.format_error(e)])

        s
    end
  end

  def save_if_needed(s), do: s
end
