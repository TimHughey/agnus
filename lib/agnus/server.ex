defmodule Agnus.Server do
  @moduledoc false

  require Logger
  use GenServer, restart: :permanent, shutdown: 1000
  use Timex

  alias Agnus.{Cache, Opts, Parser, Server}

  #
  ## Public API
  #

  def get_info(what) do
    GenServer.call(Server, {:action, :get, what}, 1000)
  end

  #
  ## GenServer Start, Init and Terminate Callbacks
  #

  def start_link(_args) do
    init_state =
      %{
        dayinfo: %{previous: %{}},
        starting_up: true,
        timeouts: 0,
        last_timeout: nil,
        opts: %{}
      }
      |> clear_dayinfo_latest()

    GenServer.start_link(__MODULE__, Opts.put(init_state), name: __MODULE__)
  end

  @impl true
  def init(s) do
    log?(s, :init_args) && Logger.info("init() args:\n#{inspect(s, pretty: true)}")

    {:ok, s, {:continue, :startup}}
  end

  @impl true
  def terminate(reason, s) do
    log?(s, :init) &&
      Logger.info(["terminating with reason ", inspect(reason, pretty: true)])
  end

  #
  ## GenServer Handle Callbacks
  #

  @impl true
  def handle_call({:current?, _opts}, _from, s) do
    reply(info_current?(s), refresh_if_needed(s))
  end

  @impl true
  def handle_call({:action, :cache_file, file}, _from, s) do
    case file do
      :none ->
        if is_binary(s.opts.cache_file) do
          File.rm(s.opts.cache_file)
        end

        reply(:none, put_in(s.opts.cache_file, :none))

      x when is_binary(x) ->
        msg = {:action, :day_refresh, [force: true]}
        GenServer.cast(self(), msg)
        reply(file, put_in(s.opts.cache_file, file))

      :query ->
        reply(s.opts.cache_file, s)
    end
  end

  # (1 of 2) latest exists
  @impl true
  def handle_call({:action, :get, what}, _from, %{dayinfo: %{latest: latest} = dayinfo} = s)
      when is_map(latest) do
    reply(get_data_from(dayinfo, latest, what), s)
  end

  # (2 of 2) latest data not available
  @impl true
  def handle_call({:action, :get, _what}, _from, s) do
    reply(false, refresh_if_needed(s))
  end

  @impl true
  def handle_call(catchall, _from, s), do: reply({:bad_call, catchall}, s)

  # (1 of 3) refresh request with force
  @impl true
  def handle_cast({:action, :day_refresh, [force: true]}, s) do
    put_in(s, [:nocache], true)
    |> refresh_now()
    |> noreply()
  end

  # (2 of 3) refresh request and a fetch is pending
  @impl true
  def handle_cast({:action, :day_refresh, _}, %{fetch_pending: true} = s), do: noreply(s)

  # (3 of 3) refresh request without force
  @impl true
  def handle_cast({:action, :day_refresh, _}, s) do
    refresh_if_needed(s) |> noreply()
  end

  @impl true
  def handle_cast({:action, :fetched_data, msg}, s) do
    Map.merge(s, msg)
    |> recv_fetched_data()
    |> noreply()
  end

  @impl true
  def handle_cast(catchall, s) do
    Logger.debug("handle_cast() unhandled msg:\n#{inspect(catchall, pretty: true)}")

    noreply(s)
  end

  @impl true
  def handle_continue(:startup, %{starting_up: true} = s) do
    # NOTE timeout not required here
    {:noreply, refresh_if_needed(s), {:continue, :startup_complete}}
  end

  @impl true
  def handle_continue(:startup_complete, %{starting_up: true} = s) do
    s = Map.drop(s, [:autostart, :starting_up])
    log?(s, :init) && Logger.info(["startup complete\n", inspect(s, pretty: true)])

    noreply(s)
  end

  @impl true
  def handle_info(:timeout, state) do
    state
    |> update_last_timeout()
    |> timeout_hook()
  end

  defp cleanup_state(s) do
    clean = [:error, :body, :parsed, :last_fetch, :nocache]
    Map.drop(s, clean)
  end

  def clear_dayinfo_latest(s) do
    put_in(s, [:dayinfo, :last_fetch], Timex.zero())
    |> put_in([:dayinfo, :latest], nil)
  end

  # (1 of 2) data is already parsed (from cache)
  def fetch_if_needed(%{parsed: _} = s), do: s

  # (2 of 2) there is already a fetch pending
  def fetch_if_needed(%{fetch_pending: true} = s), do: s

  # (3 of 3) fetch is needed
  def fetch_if_needed(%{opts: %{api: %{fetcher: fetcher}} = opts} = s) do
    # send our  opts to Fetcher to ensure alignment
    msg = {:need_fetch, self(), opts}

    case GenServer.whereis(fetcher) do
      x when is_pid(x) ->
        GenServer.cast(x, msg)
        put_in(s, [:fetch_pending], true)

      _not_a_pid ->
        s
    end
  end

  # (1 or 3) there was an error
  def finalize_dayinfo(%{error: error} = s) do
    # there was an error, replace previous with what was latest and
    # include the error

    dayinfo = %{
      previous: get_in(s, [:dayinfo, :latest]),
      latest: nil,
      last_fetch: get_in(s, [:last_fetch]),
      error: error
    }

    put_in(s, [:dayinfo], dayinfo)
  end

  # (2 or 2) sun info was successfully parsed
  def finalize_dayinfo(%{parsed: parsed} = s) do
    previous = get_in(s, [:dayinfo, :latest])

    dayinfo = %{
      previous: previous,
      latest: parsed,
      last_fetch: get_in(s, [:last_fetch])
    }

    put_in(s, [:dayinfo], dayinfo)
  end

  # (3 of 3) startup
  def finalize_dayinfo(s), do: s

  def get_data_from(dayinfo, latest, what) do
    case what do
      :all -> latest
      :keys -> Map.keys(latest)
      :last_fetch -> get_in(dayinfo, [:last_fetch])
      x when is_atom(x) -> Map.get(latest, x, false)
      x when is_list(x) -> Map.take(latest, x)
      _unknown -> []
    end
  end

  # (1 or 2) info could be current depending on contents of state
  def info_current?(%{dayinfo: %{latest: latest, last_fetch: last_fetch}} = s)
      when is_map(latest) do
    if Timex.day(last_fetch) == Timex.day(now(s)) do
      true
    else
      false
    end
  end

  # (2 of 2) info is not current, latest is not a map
  def info_current?(_s), do: false

  defp now(%{opts: %{tz: tz}}), do: Timex.now(tz)

  # (1 of 2) there is a pending fetch
  def recv_fetched_data(%{fetch_pending: true} = s) do
    Map.drop(s, [:fetch_pending])
    |> Parser.decode()
    |> Cache.save_if_needed()
    |> finalize_dayinfo()
    |> cleanup_state()
  end

  # (2 of 2) there isn't a pending fetch, this message is spurious
  def recv_fetched_data(s), do: s

  def refresh_if_needed(s) do
    Cache.load_if_possible(s)
    |> fetch_if_needed()
    |> Cache.save_if_needed()
    |> finalize_dayinfo()
    |> cleanup_state()
  end

  def refresh_now(s) do
    clear_dayinfo_latest(s) |> put_in([:nocache], true) |> refresh_if_needed()
  end

  ##
  ## GenServer Receive Loop Hooks
  ##

  defp timeout_hook(s) do
    GenServer.cast(self(), {:action, :day_refresh, opts: []})
    noreply(s)
  end

  ##
  ## State Helpers
  ##

  defp loop_timeout(%{opts: opts}) do
    timeout = Map.get(opts, :timeout, "PT1M")

    case Duration.parse(timeout) do
      {:ok, x} -> Duration.to_milliseconds(x, truncate: true)
      _x -> 60_000
    end
  end

  defp update_last_timeout(s) do
    put_in(s, [:last_timeout], now(s)) |> update_in([:timeouts], &(&1 + 1))
  end

  ##
  ## handle_* return helpers
  ##

  defp noreply(s), do: {:noreply, s, loop_timeout(s)}
  defp reply(val, s), do: {:reply, val, s, loop_timeout(s)}

  #
  ## Logging Helpers
  #

  # extract :opts from a map (usually a state)
  def log?(%{opts: %{log: log_opts}}, category, default \\ true)
      when is_atom(category) and is_boolean(default) do
    case get_in(log_opts, [category]) do
      x when is_boolean(x) -> x
      _ -> default
    end
  end
end
