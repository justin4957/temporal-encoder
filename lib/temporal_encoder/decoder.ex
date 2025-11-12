defmodule TemporalEncoder.Decoder do
  @moduledoc """
  Decodes text from a series of timestamps by analyzing timing intervals.

  Reconstructs the original message by measuring gaps between signal events
  and converting them back to morse code, then to text.
  """

  alias TemporalEncoder.MorseEncoder

  @default_base_unit_ms 200
  # 30% tolerance for timing variations
  @tolerance 0.3

  @doc """
  Decodes timestamps back to original text.

  Accepts either absolute DateTime timestamps or relative millisecond offsets.

  ## Options

  - `:base_unit_ms` - Expected base unit duration (default: 200)
  - `:tolerance` - Timing tolerance as percentage (default: 0.3 = 30%)
  - `:auto_detect_unit` - Automatically detect base unit (default: true)

  ## Examples

      iex> Decoder.decode([0, 200, 400, 800, 1400, 1800, 2200, 2400, 2600])
      {:ok, "SOS"}
  """
  def decode(timestamps, opts \\ []) when is_list(timestamps) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, @default_base_unit_ms)
    tolerance = Keyword.get(opts, :tolerance, @tolerance)
    auto_detect = Keyword.get(opts, :auto_detect_unit, true)

    with {:ok, relative_ms} <- normalize_to_relative(timestamps),
         {:ok, detected_unit} <- maybe_detect_unit(relative_ms, auto_detect, base_unit_ms),
         {:ok, morse_code} <- timestamps_to_morse(relative_ms, detected_unit, tolerance),
         {:ok, text} <- MorseEncoder.decode(morse_code) do
      {:ok, text}
    end
  end

  @doc """
  Converts timestamps to relative milliseconds.

  Handles both DateTime and integer inputs.
  """
  def normalize_to_relative([]), do: {:ok, []}

  def normalize_to_relative(timestamps) do
    case List.first(timestamps) do
      %DateTime{} = first ->
        relative =
          Enum.map(timestamps, fn dt ->
            DateTime.diff(dt, first, :millisecond)
          end)

        {:ok, relative}

      n when is_integer(n) ->
        {:ok, timestamps}

      _ ->
        {:error, "Unsupported timestamp format"}
    end
  end

  @doc """
  Automatically detects the base unit from timestamp intervals.

  Uses a robust algorithm that handles timing jitter by:
  1. Finding the smallest interval (likely 2 units: 1 signal + 1 gap)
  2. Estimating base unit as half of the minimum
  3. Validating by checking if other intervals are multiples
  """
  def detect_base_unit([]), do: {:error, "No timestamps provided"}
  def detect_base_unit([_]), do: {:error, "Need at least 2 timestamps"}

  def detect_base_unit(relative_timestamps) do
    intervals = calculate_intervals(relative_timestamps)

    # Try multiple approaches to detect the base unit
    case robust_detect(intervals) do
      unit when is_integer(unit) and unit > 0 ->
        {:ok, unit}

      _ ->
        {:error, "Could not detect base unit"}
    end
  end

  # Robust detection using minimum interval approach
  defp robust_detect(intervals) when length(intervals) < 2 do
    nil
  end

  defp robust_detect(intervals) do
    # Sort intervals to analyze distribution
    sorted = Enum.sort(intervals)
    min_interval = List.first(sorted)

    # The minimum interval is likely 2 units (dit + gap)
    # Try estimating base unit as min/2
    estimated_unit = div(min_interval, 2)

    # Validate by checking if most intervals are reasonable multiples
    if estimated_unit > 0 and validate_unit(intervals, estimated_unit) do
      estimated_unit
    else
      # Fallback: try GCD approach with rounding
      gcd_based_unit = gcd_detect(intervals)

      if gcd_based_unit > 0 and validate_unit(intervals, gcd_based_unit) do
        gcd_based_unit
      else
        nil
      end
    end
  end

  # GCD-based detection with rounding to handle jitter
  defp gcd_based_unit(intervals) do
    # Round intervals to nearest 10ms to reduce jitter impact
    rounded = Enum.map(intervals, fn i -> round(i / 10) * 10 end)
    gcd = Enum.reduce(rounded, 0, &gcd/2)
    div(gcd, 2)
  end

  # Validate that a proposed base unit makes sense
  defp validate_unit(intervals, base_unit) do
    # 30% tolerance
    tolerance = 0.3

    # Count how many intervals are close to expected multiples (2, 3, 4, 8 units)
    expected_multiples = [2, 3, 4, 6, 7, 8]

    matches =
      Enum.count(intervals, fn interval ->
        Enum.any?(expected_multiples, fn mult ->
          expected = mult * base_unit
          tolerance_amount = expected * tolerance
          abs(interval - expected) <= tolerance_amount
        end)
      end)

    # At least 70% of intervals should match expected patterns
    matches / length(intervals) >= 0.7
  end

  # Fallback GCD detection
  defp gcd_detect(intervals) do
    gcd = Enum.reduce(intervals, 0, &gcd/2)
    div(gcd, 2)
  end

  defp maybe_detect_unit(_, false, base_unit), do: {:ok, base_unit}

  defp maybe_detect_unit(timestamps, true, fallback_unit) do
    case detect_base_unit(timestamps) do
      {:ok, unit} -> {:ok, unit}
      {:error, _} -> {:ok, fallback_unit}
    end
  end

  @doc """
  Converts relative timestamps to morse code by analyzing intervals.

  Interval meanings:
  - 2 units (200ms): dit
  - 3 units (300ms): letter boundary marker (becomes '|')
  - 4 units (400ms): dah
  - 5 units (500ms): dit + letter boundary
  - 7 units (700ms): dah + letter boundary

  Returns morse code with '|' characters marking letter boundaries.
  """
  def timestamps_to_morse(relative_timestamps, base_unit_ms, tolerance \\ @tolerance) do
    cond do
      length(relative_timestamps) == 0 ->
        {:ok, ""}

      length(relative_timestamps) == 1 ->
        {:ok, "."}

      true ->
        intervals = calculate_intervals(relative_timestamps)

        # Decode each interval - returns list of symbols (signal + optional boundary)
        # Each interval tells us what the PREVIOUS timestamp represented
        # The last timestamp doesn't represent a signal itself - it just marks
        # the end point of the previous signal, allowing us to calculate its duration
        symbols_lists =
          Enum.map(intervals, fn interval ->
            decode_interval(interval, base_unit_ms)
          end)

        # Flatten all symbols into a single list
        # Note: We do NOT add a symbol for the last timestamp, as it's just
        # a timing marker for the previous signal
        all_symbols =
          symbols_lists
          |> List.flatten()

        # Build morse pattern list: split by boundaries into letters and words
        morse_patterns =
          all_symbols
          |> Enum.chunk_by(fn s -> s in ["|", "/"] end)
          |> Enum.flat_map(fn chunk ->
            cond do
              # Skip letter boundaries
              chunk == ["|"] -> []
              # Keep word boundaries
              chunk == ["/"] -> ["/"]
              # Group dots/dashes into letter
              true -> [Enum.join(chunk, "")]
            end
          end)

        {:ok, morse_patterns}
    end
  end

  # Decode a single interval to determine what the previous timestamp represented
  # Returns a list of symbols (signal + optional boundary)
  defp decode_interval(interval, base_unit_ms) do
    units = interval / base_unit_ms

    result =
      cond do
        # Check combined intervals first (with tighter tolerances)
        # 10 units = dah + word boundary
        abs(units - 10.0) < 0.8 ->
          ["-", "/"]

        # 8 units = dit + word boundary
        abs(units - 8.0) < 0.8 ->
          [".", "/"]

        # 7 units = dah + letter boundary
        abs(units - 7.0) < 0.8 ->
          ["-", "|"]

        # 5 units = dit + letter boundary
        abs(units - 5.0) < 0.8 ->
          [".", "|"]

        # Then check simple intervals
        # 6 units = word boundary only
        abs(units - 6.0) < 1.0 ->
          ["/"]

        # 4 units = dah
        abs(units - 4.0) < 0.8 ->
          ["-"]

        # 3 units = letter boundary only
        abs(units - 3.0) < 0.8 ->
          ["|"]

        # 2 units = dit
        abs(units - 2.0) < 0.8 ->
          ["."]

        # Default: choose closest
        true ->
          targets = [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 10.0]
          closest = Enum.min_by(targets, fn target -> abs(units - target) end)

          case closest do
            2.0 -> ["."]
            3.0 -> ["|"]
            4.0 -> ["-"]
            5.0 -> [".", "|"]
            6.0 -> ["/"]
            7.0 -> ["-", "|"]
            8.0 -> [".", "/"]
            10.0 -> ["-", "/"]
          end
      end

    result
  end

  # Infer what the last timestamp represents
  # The last timestamp has no interval after it to decode, so we need to infer
  # what signal it was. Since there's no boundary marker after it (by definition,
  # it's the last signal), we can look at the pattern from the previous interval.
  # The previous interval tells us what the second-to-last timestamp was.
  # The last timestamp itself should be inferred as the same type of signal
  # as indicated by the previous interval's signal component.
  defp infer_last_symbol(last_interval, base_unit_ms) do
    units = last_interval / base_unit_ms

    # Extract just the signal part from the last interval
    # (ignoring any boundary that was already processed)
    cond do
      # Combined intervals with dah
      # dah + word boundary
      # dah + letter boundary
      abs(units - 10.0) < 0.8 or
          abs(units - 7.0) < 0.8 ->
        ["-"]

      # Combined intervals with dit
      # dit + word boundary
      # dit + letter boundary
      abs(units - 8.0) < 0.8 or
          abs(units - 5.0) < 0.8 ->
        ["."]

      # Simple signal intervals - last timestamp is same type
      # dah
      abs(units - 4.0) < 0.8 ->
        ["-"]

      # dit
      abs(units - 2.0) < 0.8 ->
        ["."]

      # Boundary-only intervals - can't infer, assume dit
      # word boundary only
      # letter boundary only
      abs(units - 6.0) < 1.0 or
          abs(units - 3.0) < 0.8 ->
        ["."]

      # Default: determine based on closest pattern
      true ->
        targets = [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 10.0]
        closest = Enum.min_by(targets, fn target -> abs(units - target) end)

        case closest do
          10.0 -> ["-"]
          8.0 -> ["."]
          7.0 -> ["-"]
          5.0 -> ["."]
          4.0 -> ["-"]
          _ -> ["."]
        end
    end
  end

  # Clean up morse code spacing
  defp normalize_morse_spacing(morse) do
    morse
    # Collapse multiple spaces
    |> String.replace(~r/\s+/, " ")
    # Ensure proper word separator format
    |> String.replace(" / ", " / ")
    |> String.trim()
  end

  @doc """
  Provides detailed analysis of timestamp intervals.

  Returns information about detected patterns and timing.
  """
  def analyze_timing(timestamps, opts \\ []) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, @default_base_unit_ms)

    with {:ok, relative_ms} <- normalize_to_relative(timestamps),
         {:ok, detected_unit} <- detect_base_unit(relative_ms) do
      intervals = calculate_intervals(relative_ms)
      interval_units = Enum.map(intervals, fn i -> round(i / detected_unit) end)

      %{
        signal_count: length(timestamps),
        detected_base_unit_ms: detected_unit,
        expected_base_unit_ms: base_unit_ms,
        unit_match: close_to?(detected_unit, base_unit_ms, base_unit_ms * 0.3),
        intervals_ms: intervals,
        intervals_in_units: interval_units,
        total_duration_ms: List.last(relative_ms) || 0
      }
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Helper functions

  defp calculate_intervals([]), do: []
  defp calculate_intervals([_]), do: []

  defp calculate_intervals(timestamps) do
    timestamps
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [a, b] -> b - a end)
  end

  defp close_to?(value, target, tolerance) do
    abs(value - target) <= tolerance
  end

  defp gcd(a, 0), do: abs(a)
  defp gcd(a, b), do: gcd(b, rem(a, b))
end
