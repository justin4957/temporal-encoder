defmodule TemporalEncoder.TimestampGenerator do
  @moduledoc """
  Generates precise timestamps from morse code using standard timing.

  ## Morse Timing Convention

  Using a base unit (default 200ms):
  - Dit (dot): 1 unit of signal ON
  - Dah (dash): 3 units of signal ON
  - Gap between symbols in same letter: 1 unit OFF
  - Gap between letters: 3 units OFF
  - Gap between words: 7 units OFF

  Timestamps represent the START of each signal pulse.
  """

  @default_base_unit_ms 200

  @doc """
  Generates timestamps from morse code string.

  ## Options

  - `:base_unit_ms` - Duration of one unit in milliseconds (default: 200)
  - `:start_time` - Starting DateTime (default: DateTime.utc_now/0)
  - `:format` - `:absolute` for DateTime or `:relative` for milliseconds (default: :absolute)

  ## Examples

      iex> generate("... --- ...", format: :relative)
      {:ok, [0, 200, 400, 800, 1400, 1800, 2200, 2400, 2600]}
  """
  def generate(morse_code, opts \\ []) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, @default_base_unit_ms)
    start_time = Keyword.get(opts, :start_time, DateTime.utc_now())
    format = Keyword.get(opts, :format, :absolute)

    relative_timestamps = generate_relative_timestamps(morse_code, base_unit_ms)

    timestamps = case format do
      :relative ->
        relative_timestamps

      :absolute ->
        Enum.map(relative_timestamps, fn offset_ms ->
          DateTime.add(start_time, offset_ms, :millisecond)
        end)
    end

    {:ok, timestamps}
  end

  @doc """
  Generates relative timestamps (milliseconds from start).

  Returns a list of integers representing milliseconds from start time.

  Interval scheme:
  - 2 units between timestamps = dit
  - 4 units between timestamps = dah
  - 3 units gap (no timestamp) = letter boundary
  - 6 units gap (no timestamp) = word boundary
  """
  def generate_relative_timestamps(morse_patterns, base_unit_ms \\ @default_base_unit_ms) when is_list(morse_patterns) do
    {_, timestamps_rev} = morse_patterns
    |> Enum.with_index()
    |> Enum.reduce({0, []}, fn {pattern, idx}, {current_time, acc} ->
      case pattern do
        "/" ->
          # Word boundary: advance 6 units without emitting timestamp
          {current_time + (6 * base_unit_ms), acc}

        letter_morse ->
          # Process each dot/dash in the letter
          {new_time, new_acc} = letter_morse
          |> String.graphemes()
          |> Enum.reduce({current_time, acc}, fn char, {time, timestamps} ->
            case char do
              "." ->
                # Dit: emit timestamp, advance 2 units
                {time + (2 * base_unit_ms), [time | timestamps]}

              "-" ->
                # Dah: emit timestamp, advance 4 units
                {time + (4 * base_unit_ms), [time | timestamps]}

              _ ->
                {time, timestamps}
            end
          end)

          # Add 3-unit letter boundary gap ONLY if next pattern is not "/"
          next_pattern = Enum.at(morse_patterns, idx + 1)
          gap = if next_pattern == "/", do: 0, else: 3 * base_unit_ms

          {new_time + gap, new_acc}
      end
    end)

    Enum.reverse(timestamps_rev)
  end

  # Fallback for string input (convert to patterns first)
  def generate_relative_timestamps(morse_code, base_unit_ms) when is_binary(morse_code) do
    # Split into letter patterns
    patterns = String.split(morse_code, " ", trim: true)
    generate_relative_timestamps(patterns, base_unit_ms)
  end

  @doc """
  Calculates the total duration for a morse code message.

  ## Examples

      iex> duration("... --- ...", 200)
      3000
  """
  def duration(morse_code, base_unit_ms \\ @default_base_unit_ms) do
    case generate_relative_timestamps(morse_code, base_unit_ms) do
      [] -> 0
      timestamps -> List.last(timestamps)
    end
  end

  @doc """
  Provides detailed timing information for a morse code message.

  Returns a map with timing breakdown.
  """
  def timing_info(morse_code, base_unit_ms \\ @default_base_unit_ms) do
    timestamps = generate_relative_timestamps(morse_code, base_unit_ms)
    signal_count = length(timestamps)

    {dit_count, dah_count, letter_gaps, word_gaps} =
      morse_code
      |> String.graphemes()
      |> Enum.reduce({0, 0, 0, 0}, fn char, {dits, dahs, letters, words} ->
        case char do
          "." -> {dits + 1, dahs, letters, words}
          "-" -> {dits, dahs + 1, letters, words}
          " " -> {dits, dahs, letters + 1, words}
          "/" -> {dits, dahs, letters, words + 1}
          _ -> {dits, dahs, letters, words}
        end
      end)

    %{
      signal_count: signal_count,
      dit_count: dit_count,
      dah_count: dah_count,
      letter_gaps: letter_gaps,
      word_gaps: word_gaps,
      duration_ms: (if signal_count > 0, do: List.last(timestamps), else: 0),
      base_unit_ms: base_unit_ms,
      timestamps: timestamps
    }
  end
end
