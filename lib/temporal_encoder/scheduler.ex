defmodule TemporalEncoder.Scheduler do
  @moduledoc """
  Schedules actions (API calls or callbacks) at precise timestamps.

  Provides high-precision scheduling using Elixir processes and timers.
  """

  require Logger

  @doc """
  Schedules actions at the given timestamps.

  ## Options

  - `:url` - API endpoint URL (required if no :callback)
  - `:method` - HTTP method (default: :post)
  - `:headers` - HTTP headers (default: [])
  - `:body` - Optional HTTP body (default: "")
  - `:callback` - Function to call at each timestamp (default: nil)
  - `:metadata` - Additional metadata to pass to callback (default: %{})

  Either :url or :callback must be provided.

  ## Examples

      iex> Scheduler.schedule([0, 200, 400], url: "https://api.example.com/ping")
      {:ok, %{scheduled: 3, start_time: ~U[...]}}

      iex> Scheduler.schedule([0, 200, 400], callback: fn ts -> IO.puts(ts) end)
      {:ok, %{scheduled: 3, start_time: ~U[...]}}
  """
  def schedule(relative_timestamps, opts \\ []) do
    url = Keyword.get(opts, :url)
    callback = Keyword.get(opts, :callback)

    cond do
      callback != nil ->
        schedule_with_callback(relative_timestamps, callback, opts)

      url != nil ->
        schedule_with_http(relative_timestamps, url, opts)

      true ->
        {:error, "Either :url or :callback must be provided"}
    end
  end

  @doc """
  Schedules callbacks at the given timestamps.
  """
  def schedule_with_callback(relative_timestamps, callback, opts \\ []) do
    metadata = Keyword.get(opts, :metadata, %{})
    start_time = DateTime.utc_now()

    parent_process = self()

    Enum.each(relative_timestamps, fn timestamp_ms ->
      Task.start(fn ->
        Process.sleep(timestamp_ms)

        try do
          callback.(%{
            scheduled_time: DateTime.add(start_time, timestamp_ms, :millisecond),
            actual_time: DateTime.utc_now(),
            offset_ms: timestamp_ms,
            metadata: metadata
          })

          send(parent_process, {:signal_sent, :ok, timestamp_ms})
        rescue
          error ->
            Logger.error("Callback error at #{timestamp_ms}ms: #{inspect(error)}")
            send(parent_process, {:signal_sent, {:error, error}, timestamp_ms})
        end
      end)
    end)

    {:ok,
     %{
       scheduled: length(relative_timestamps),
       start_time: start_time,
       end_time: DateTime.add(start_time, List.last(relative_timestamps) || 0, :millisecond)
     }}
  end

  @doc """
  Schedules HTTP requests at the given timestamps.
  """
  def schedule_with_http(relative_timestamps, url, opts \\ []) do
    method = Keyword.get(opts, :method, :post)
    headers = Keyword.get(opts, :headers, [])
    body = Keyword.get(opts, :body, "")
    metadata = Keyword.get(opts, :metadata, %{})
    start_time = DateTime.utc_now()

    parent_process = self()

    Enum.each(relative_timestamps, fn timestamp_ms ->
      Task.start(fn ->
        Process.sleep(timestamp_ms)

        scheduled_time = DateTime.add(start_time, timestamp_ms, :millisecond)
        actual_time = DateTime.utc_now()

        # Add timing headers
        timing_headers = [
          {"X-Scheduled-Time", DateTime.to_iso8601(scheduled_time)},
          {"X-Actual-Time", DateTime.to_iso8601(actual_time)},
          {"X-Offset-Ms", Integer.to_string(timestamp_ms)}
          | headers
        ]

        # Merge metadata into body if JSON
        final_body =
          case Jason.encode(
                 Map.merge(metadata, %{
                   signal_time: DateTime.to_iso8601(actual_time),
                   offset_ms: timestamp_ms
                 })
               ) do
            {:ok, json} -> json
            _ -> body
          end

        result =
          case method do
            :get -> HTTPoison.get(url, timing_headers)
            :post -> HTTPoison.post(url, final_body, timing_headers)
            :put -> HTTPoison.put(url, final_body, timing_headers)
            :delete -> HTTPoison.delete(url, timing_headers)
            _ -> {:error, "Unsupported HTTP method: #{method}"}
          end

        case result do
          {:ok, response} ->
            Logger.debug("Signal sent at #{timestamp_ms}ms: HTTP #{response.status_code}")
            send(parent_process, {:signal_sent, :ok, timestamp_ms})

          {:error, error} ->
            Logger.error("HTTP error at #{timestamp_ms}ms: #{inspect(error)}")
            send(parent_process, {:signal_sent, {:error, error}, timestamp_ms})
        end
      end)
    end)

    {:ok,
     %{
       scheduled: length(relative_timestamps),
       start_time: start_time,
       end_time: DateTime.add(start_time, List.last(relative_timestamps) || 0, :millisecond),
       url: url,
       method: method
     }}
  end

  @doc """
  Waits for all scheduled signals to complete and returns results.

  ## Options

  - `:timeout` - Maximum time to wait in milliseconds (default: duration + 5000)
  """
  def await_completion(scheduled_count, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 60_000)
    await_signals(scheduled_count, [], timeout)
  end

  defp await_signals(0, results, _timeout), do: {:ok, Enum.reverse(results)}

  defp await_signals(remaining, results, timeout) do
    receive do
      {:signal_sent, status, timestamp_ms} ->
        await_signals(remaining - 1, [{timestamp_ms, status} | results], timeout)
    after
      timeout ->
        {:error,
         "Timeout waiting for signals. Received #{length(results)}, expected #{remaining + length(results)}"}
    end
  end
end
