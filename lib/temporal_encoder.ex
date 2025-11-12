defmodule TemporalEncoder do
  @moduledoc """
  Encodes text messages into precise timestamps using morse code timing.

  The information is carried entirely in the temporal spacing between events,
  with no payload data required. This can be used to trigger API calls at
  precise times where the timing itself conveys the message.

  ## Morse Code Timing

  Standard morse timing uses a base unit (typically 1 second):
  - Dit (dot): 1 unit
  - Dah (dash): 3 units
  - Gap between symbols: 1 unit
  - Gap between letters: 3 units
  - Gap between words: 7 units
  """

  alias TemporalEncoder.{MorseEncoder, TimestampGenerator, Scheduler, Decoder}

  @doc """
  Encodes a text string into a series of precise timestamps.

  ## Options

  - `:base_unit_ms` - Base timing unit in milliseconds (default: 200)
  - `:start_time` - Starting timestamp (default: current time)
  - `:format` - Output format `:absolute` or `:relative` (default: `:absolute`)

  ## Examples

      iex> TemporalEncoder.encode("SOS")
      {:ok, [~U[2025-01-15 10:00:00.000Z], ~U[2025-01-15 10:00:00.200Z], ...]}

      iex> TemporalEncoder.encode("SOS", format: :relative)
      {:ok, [0, 200, 400, 800, 1400, ...]}
  """
  def encode(text, opts \\ []) do
    with {:ok, morse} <- MorseEncoder.encode(text),
         {:ok, timestamps} <- TimestampGenerator.generate(morse, opts) do
      {:ok, timestamps}
    end
  end

  @doc """
  Decodes a series of timestamps back into the original text.

  ## Examples

      iex> timestamps = [0, 200, 400, 800, 1400, 1800, 2200, 2400, 2600]
      iex> TemporalEncoder.decode(timestamps)
      {:ok, "SOS"}
  """
  def decode(timestamps, opts \\ []) do
    Decoder.decode(timestamps, opts)
  end

  @doc """
  Schedules API calls at the encoded timestamps.

  ## Options

  - `:url` - API endpoint URL (required)
  - `:method` - HTTP method (default: :post)
  - `:headers` - HTTP headers (default: [])
  - `:base_unit_ms` - Base timing unit in milliseconds (default: 200)
  - `:callback` - Function to call at each timestamp instead of HTTP request

  ## Examples

      iex> TemporalEncoder.schedule("HELLO", url: "https://api.example.com/ping")
      {:ok, %{scheduled: 35, start_time: ~U[2025-01-15 10:00:00.000Z]}}
  """
  def schedule(text, opts \\ []) do
    with {:ok, timestamps} <- encode(text, format: :relative),
         {:ok, result} <- Scheduler.schedule(timestamps, opts) do
      {:ok, result}
    end
  end

  @doc """
  Returns information about the encoded message.

  ## Examples

      iex> TemporalEncoder.info("HELLO")
      {:ok, %{
        character_count: 5,
        signal_count: 35,
        duration_ms: 5600,
        morse_code: ".... . .-.. .-.. ---"
      }}
  """
  def info(text, opts \\ []) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, 200)

    with {:ok, morse} <- MorseEncoder.encode(text),
         {:ok, timestamps} <- TimestampGenerator.generate(morse,
           Keyword.merge(opts, [format: :relative])) do
      duration_ms = List.last(timestamps) || 0

      {:ok, %{
        character_count: String.length(text),
        signal_count: length(timestamps),
        duration_ms: duration_ms,
        morse_code: morse,
        base_unit_ms: base_unit_ms
      }}
    end
  end
end
