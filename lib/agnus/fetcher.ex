defmodule Agnus.Fetcher do
  @moduledoc false

  require Logger

  use GenServer, restart: :permanent, shutdown: 2000
  use Timex

  alias HTTPoison.Response

  alias Agnus.Opts

  def start_link(_args) do
    init_state = %{reply_to: nil, opts: %{}, body: nil, last_fetch: Timex.zero()}
    GenServer.start_link(__MODULE__, Opts.put(init_state), name: __MODULE__)
  end

  @impl true
  def init(s) do
    {:ok, s, {:continue, :startup}}
  end

  @impl true
  def handle_cast({:need_fetch, reply_to, opts}, s) do
    s = put_in(s, [:reply_to], reply_to) |> put_in([:opts], opts) |> fetch_if_needed()

    {:noreply, s}
  end

  @impl true
  def handle_continue(:startup, s) do
    {:noreply, fetch_json_reschedule_if_needed(s)}
  end

  @impl true
  def handle_info(:need_fetch, s) do
    {:noreply, fetch_json_reschedule_if_needed(s)}
  end

  def fetch_if_needed(%{last_fetch: %DateTime{} = last_fetch} = s) do
    timeout = timeout_ms(s)

    case Timex.diff(now(s), last_fetch, :milliseconds) do
      diff when diff > timeout -> fetch_json_reschedule_if_needed(s)
      _diff -> reply_to_requester(s)
    end
  end

  def fetch_json_reschedule_if_needed(s) do
    fetch_json(s) |> reschedule_fetch_if_needed()
  end

  def fetch_json(%{opts: %{api: api_opts}} = s) do
    uri = [api_opts.url, "/json"]
    now = now(s)
    today = Timex.to_date(now)
    params = %{lat: api_opts.lat, lng: api_opts.lng, formatted: 0, date: today}

    request_opts = [
      params: params,
      timeout: api_opts.timeout,
      recv_timeout: api_opts.recv_timeout,
      hackney: [pool: :default]
    ]

    case HTTPoison.get(uri, [], request_opts) do
      {:ok, %Response{body: body}} ->
        Map.merge(s, %{last_fetch: now, body: body}) |> reply_to_requester()

      error ->
        put_in(s, [:error], error) |> Map.drop([:body])
    end
  end

  def now(%{opts: %{tz: tz}}) do
    Timex.now(tz)
  end

  # (1 of 2) another process requested a fetch
  def reply_to_requester(%{reply_to: reply_to} = s) when is_pid(reply_to) do
    msg = Map.take(s, [:body, :last_fetch])

    GenServer.cast(reply_to, {:action, :fetched_data, msg})

    Map.drop(s, [:reply_to])
  end

  # (2 of 2) startup fetch
  def reply_to_requester(s), do: s

  # (1 of 2) an error was encountered
  def reschedule_fetch_if_needed(%{error: e} = s) do
    Logger.warn("sun info fetch failed: #{inspect(e, pretty: true)}")

    Process.send_after(self(), :need_fetch, timeout_ms(s))

    Map.drop(s, [:error])
  end

  # (2 of 2) all is well
  def reschedule_fetch_if_needed(s), do: s

  def timeout_ms(%{opts: %{timeout: timeout}}) do
    case Duration.parse(timeout) do
      {:ok, x} -> Duration.to_milliseconds(x, truncate: true)
      _x -> 60_000
    end
  end
end
