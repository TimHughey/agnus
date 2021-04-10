defmodule Agnus.DayInfo do
  @moduledoc """
  Agnus Dayinfo Server
  """

  require Logger
  use GenServer
  use Timex

  use Agnus.Config.Helper

  #
  ## Macros
  #

  defmacrop if_latest_valid(state, do: if_block) do
    quote do
      %{day_info: %{latest: latest} = day_info} = unquote(state)

      if Map.has_key?(day_info, :error) or is_nil(latest) do
        false
      else
        unquote(if_block)
      end
    end
  end

  #
  ## Public API
  #

  @doc """
  Is the data available for today?

  ## Examples

      iex> Agnus.current?()
      iex> true

  """
  def current?(opts \\ []) when is_list(opts) do
    GenServer.call(__MODULE__, {:current?, opts})
  end

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
  def get_info(:all) do
    state = state()

    if_latest_valid(state) do
      %{day_info: %{latest: latest}} = state
      latest
    end
  end

  def get_info(key) when is_atom(key) do
    get_info(:all) |> Map.get(key)
  end

  def get_info(keys) when is_list(keys) do
    state = state()

    if_latest_valid(state) do
      %{day_info: %{latest: latest}} = state
      Map.take(latest, keys)
    end
  end

  @doc """
  Get the sun info keys available

  ## Examples

      iex> keys = Agnus.keys()
      iex> [:sunrise, :sunset] in keys
      iex> Enum.count(keys) == 10

  """
  def keys do
    state = state()

    if_latest_valid(state) do
      %{day_info: %{latest: latest}} = state
      Map.keys(latest)
    end
  end

  @doc false
  def last_refresh do
    state = state()

    if_latest_valid(state) do
      %{day_info: %{last_fetch: last_refresh}} = state
      last_refresh
    end
  end

  @doc false
  def state, do: :sys.get_state(__MODULE__)

  ##
  ## Specific Sun Info Key Access
  ##

  @doc """
  Get noon

  ## Examples

      iex> noon = Agnus.noon()
      iex> %DateTime{} = sunrise
  """
  @doc since: "0.0.3"
  def noon do
    get_info(:all) |> Map.get(:solar_noon)
  end

  @doc """
  Get sunrise

  ## Examples

      iex> sunrise = Agnus.sunrise()
      iex> %DateTime{} = sunrise
  """
  @doc since: "0.0.3"
  def sunrise do
    get_info(:all) |> Map.get(:sunrise)
  end

  @doc """
  Get sunset

  ## Examples

      iex> sunet = Agnus.sunset()
      iex> %DateTime{} = sunset
  """
  @doc since: "0.0.3"
  def sunset do
    get_info(:all) |> Map.get(:sunset)
  end

  @doc """
  Trigger a refresh of the sun info for today

  ## Examples

      iex> :ok = Agnus.trigger_sun_info_refresh()

  > The most recent data is cached and, as such, repeated calls to this function
  > on the same day are no ops.

  """
  def trigger_day_info_refresh(opts \\ []) when is_list(opts),
    do: GenServer.cast(__MODULE__, {:action, :day_refresh, opts})

  #
  ## GenServer Start, Init and Terminate Callbacks
  #

  @doc false
  def start_link(args) when is_list(args) do
    import Agnus.Time.Helper, only: [utc_now: 0]

    GenServer.start_link(
      __MODULE__,
      Map.merge(Enum.into(args, %{}), %{
        autostart: Keyword.get(args, :autostart, true),
        opts: module_opts(default_opts()),
        day_info: %{last_fetch: nil, latest: %{}, previous: %{}},
        starting_up: true,
        timeouts: 0,
        last_timeout: utc_now()
      }),
      name: __MODULE__
    )
  end

  @doc false
  @impl true
  def init(%{autostart: autostart, opts: _opts} = s) do
    log?(s, :init_args) && Logger.info(["init():\n", inspect(s, pretty: true)])

    if autostart do
      Process.flag(:trap_exit, true)

      {:ok, s, {:continue, {:startup}}}
    else
      {:ok, s}
    end
  end

  @doc false
  @impl true
  def terminate(reason, s) do
    log?(s, :init) &&
      Logger.info(["terminating with reason ", inspect(reason, pretty: true)])
  end

  #
  ## GenServer Handle Callbacks
  #

  @doc false
  @impl true
  def handle_call(
        {:current?, _opts},
        _from,
        %{day_info: %{last_fetch: _last_fetch}} = s
      ) do
    reply(info_current?(s), s)
  end

  @doc false
  @impl true
  def handle_call(catchall, _from, s), do: reply({:bad_call, catchall}, s)

  @doc false
  @impl true
  def handle_cast({:action, :day_refresh, _opts}, %{} = s) do
    noreply(refresh_day_info(s))
  end

  @doc false
  @impl true
  def handle_cast(catchall, s) do
    Logger.warn(["handle_cast() unhandled:\n", inspect(catchall, pretty: true)])
    noreply(s)
  end

  @doc false
  @impl true
  def handle_continue(
        {:startup},
        %{
          opts: _opts,
          day_info: %{last_fetch: nil},
          starting_up: true
        } = s
      ) do
    state = refresh_day_info(s) |> log_refresh_day_info()

    # NOTE  no timeout required here
    {:noreply, state, {:continue, {:startup_complete}}}
  end

  @doc false
  @impl true
  def handle_continue(
        {:startup_complete},
        %{opts: _opts, starting_up: true} = s
      ) do
    log?(s, :init) && Logger.info(["startup complete"])

    put_in(s[:starting_up], false)
    |> noreply()
  end

  @doc false
  @impl true
  def handle_info(:timeout, state) do
    import Agnus.Time.Helper, only: [utc_now: 0]

    state
    |> update_last_timeout()
    |> timeout_hook()
  end

  #
  ## Private Functions
  #

  defp convert_datetimes(%{sunrise: _, sunset: _} = x, opts)
       when is_list(opts) do
    raw_map =
      Map.take(x, [
        :astronomical_twilight_begin,
        :astronomical_twilight_end,
        :civil_twilight_begin,
        :civil_twilight_end,
        :nautical_twilight_begin,
        :nautical_twilight_end,
        :solar_noon,
        :sunrise,
        :sunset
      ])

    Enum.reduce(raw_map, Map.take(x, [:day_length]), fn {k, v}, acc ->
      Map.put(
        acc,
        k,
        Timex.parse!(v, "{ISO:Extended}")
        |> Timex.to_datetime(Keyword.get(opts, :tz, "America/New_York"))
      )
    end)
  end

  defp info_current?(%{} = s) do
    if_latest_valid(s) do
      import Timex, only: [day: 1, now: 1]

      %{opts: opts, day_info: %{last_fetch: last_fetch} = day_info} = s
      tz = Keyword.get(opts, :tz)

      cond do
        is_nil(last_fetch) or Map.has_key?(day_info, :error) ->
          false

        day(last_fetch) != day(now(tz)) ->
          # suninfo is not current.  send ourself a message to
          # do an update because the timeout based update is likely
          # being starved by frequent requests from other processes.
          GenServer.cast(__MODULE__, {:action, :day_refresh, []})
          false

        true ->
          true
          # the info is current
      end
    end
  end

  defp refresh_day_info(%{opts: opts, day_info: %{latest: previous}} = s) do
    import HTTPoison, only: [get: 3]
    import Jason, only: [decode: 2]
    import Timex, only: [now: 1, to_date: 1]

    alias HTTPoison.Response

    tz = Keyword.get(opts, :tz, "America/New_York")

    today = now(tz) |> to_date()

    api_opts = Keyword.get(opts, :api, [])

    url = Keyword.get(api_opts, :url, nil)
    lat_and_lng = Keyword.take(api_opts, [:lat, :lng])

    params = Keyword.merge(lat_and_lng, formatted: 0, date: today) |> Enum.into(%{})

    with {:current, false} <- {:current, info_current?(s)},
         url when is_binary(url) <- url,
         # append required uri info
         uri <- [url, "/json"],
         # perform the HTTPS fetch and pattern match to get the body
         {:ok, %Response{body: body}} <- get(uri, [], params: params),
         # decode the JSON and pattern match the results
         {:ok, %{results: latest, status: "OK"}} <- decode(body, keys: :atoms),
         # convert the resulting DateTimes to the configured timezone
         latest <- convert_datetimes(latest, opts),
         # build the new day info map noting that the old latest becomes previous
         day_info <- %{previous: previous, latest: latest, last_fetch: now(tz)},
         # remove the error key (if needed)
         day_info <- Map.delete(day_info, :error) do
      # all is well
      # simply update state's day info
      %{s | day_info: day_info}
    else
      # day info is current, avoid unnecessary API calls by doing nothing
      {:current, true} ->
        s

      error ->
        # there was an error, replace previous with what was latest and
        # include the error
        day_info = %{
          previous: previous,
          latest: %{},
          last_fetch: now(tz),
          error: error
        }

        %{s | day_info: day_info}
    end
  end

  ##
  ## GenServer Receive Loop Hooks
  ##

  defp timeout_hook(%{opts: opts} = s) do
    GenServer.cast(__MODULE__, {:action, :day_refresh, opts})
    noreply(s)
  end

  ##
  ## State Helpers
  ##

  defp loop_timeout(%{opts: opts}) do
    import Agnus.Time.Helper, only: [list_to_ms: 2]

    list_to_ms(opts[:timeout], minutes: 1)
  end

  defp update_last_timeout(s) do
    import Agnus.Time.Helper, only: [utc_now: 0]

    put_in(s[:last_timeout], utc_now())
    |> Map.update(:timeouts, 1, &(&1 + 1))
  end

  ##
  ## handle_* return helpers
  ##

  defp noreply(s), do: {:noreply, s, loop_timeout(s)}
  defp reply(val, s), do: {:reply, val, s, loop_timeout(s)}

  #
  ## Constants
  #

  defp default_opts,
    do: [
      log: [init: false, init_args: false, default_opts: true],
      tz: "America/New_York",
      api: [
        url: "https://api.sunrise-sunset.org",
        lat: 40.2108,
        lng: -74.011
      ]
    ]

  #
  ## Logging Helpers
  #
  defp log_refresh_day_info(%{day_info: %{error: error}} = s) do
    Logger.warn([
      "could not fetch sun info:\n",
      inspect(error, pretty: true)
    ])

    # always return what was passed so this can be used ina pipeline
    s
  end

  # day_info does not have an error key
  defp log_refresh_day_info(%{day_info: _} = s), do: s
end
