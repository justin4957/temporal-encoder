defmodule TemporalEncoder.MusicEncoder.RhythmEncoder do
  @moduledoc """
  Encodes information in rhythmic patterns and note durations.

  Uses the binary representation of characters encoded in rhythm to create
  a secondary information channel. This is harder to detect than pitch encoding
  as rhythm variations are common in natural music.
  """

  @doc """
  Converts a character to a sequence of notes with durations encoding the binary representation.

  Each bit of the character's ASCII value is encoded as a note duration:
  - 0 bit: eighth note (0.25 beats)
  - 1 bit: quarter note (0.5 beats)

  ## Examples

      iex> RhythmEncoder.char_to_rhythm_sequence("A", :c_major)
      [
        %{pitch: 60, duration: 0.5, velocity: 80, position: 0},  # 1
        %{pitch: 62, duration: 0.25, velocity: 80, position: 1}, # 0
        %{pitch: 64, duration: 0.5, velocity: 80, position: 2},  # 1
        # ... more notes for remaining bits
      ]
  """
  def char_to_rhythm_sequence(char, key \\ :c_major) when is_binary(char) do
    ascii_value = :binary.first(char)
    binary_string = Integer.to_string(ascii_value, 2) |> String.pad_leading(8, "0")
    scale = get_base_pitches(key)

    binary_string
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map(fn {bit, idx} ->
      duration = if bit == "1", do: 0.5, else: 0.25
      pitch = Enum.at(scale, rem(idx, length(scale)))

      %{pitch: pitch, duration: duration, velocity: 80, position: idx}
    end)
  end

  @doc """
  Extracts character from a rhythm sequence by analyzing durations.

  Decodes the binary pattern from note durations back to ASCII character.
  """
  def rhythm_sequence_to_char(notes) when is_list(notes) do
    binary_string =
      notes
      |> Enum.map(fn note ->
        # Longer duration = 1, shorter duration = 0
        if note.duration >= 0.4, do: "1", else: "0"
      end)
      |> Enum.join()

    case Integer.parse(binary_string, 2) do
      {ascii_val, ""} when ascii_val > 0 and ascii_val < 128 ->
        <<ascii_val::utf8>>

      _ ->
        "?"
    end
  end

  @doc """
  Maps a single character to a note duration based on its ASCII value.

  Used in multi-layer encoding where duration is one of several encoding dimensions.

  ## Examples

      iex> RhythmEncoder.char_to_duration("A")
      0.5

      iex> RhythmEncoder.char_to_duration("E")
      0.375
  """
  def char_to_duration(char) when is_binary(char) do
    ascii_val = :binary.first(char)

    # Map ASCII value to musical durations
    # Common durations: 0.25 (eighth), 0.375 (dotted eighth), 0.5 (quarter), 0.75 (dotted quarter), 1.0 (half)
    durations = [0.25, 0.375, 0.5, 0.75, 1.0]
    duration_index = rem(ascii_val, length(durations))

    Enum.at(durations, duration_index)
  end

  @doc """
  Analyzes rhythm patterns for statistical anomalies.

  Natural music typically has certain rhythmic distributions. Encoded data
  may have more uniform or unusual distributions.
  """
  def analyze_rhythm_patterns(notes) when is_list(notes) do
    durations = Enum.map(notes, & &1.duration)

    %{
      total_duration: Enum.sum(durations),
      duration_variety: length(Enum.uniq(durations)),
      duration_distribution: Enum.frequencies(durations),
      average_duration: calculate_average(durations),
      rhythm_entropy: calculate_rhythm_entropy(durations),
      syncopation_index: calculate_syncopation(notes)
    }
  end

  @doc """
  Detects potential encoding in rhythm by comparing to expected natural distribution.

  Returns a suspicion score from 0.0 (natural) to 1.0 (highly suspicious).
  """
  def detect_rhythm_encoding(notes) when is_list(notes) do
    analysis = analyze_rhythm_patterns(notes)

    # Natural music tends to favor certain durations (quarter and eighth notes)
    # and has moderate entropy. Too uniform or too random suggests encoding.
    entropy_score = normalize_entropy_score(analysis.rhythm_entropy)
    variety_score = normalize_variety_score(analysis.duration_variety, length(notes))
    syncopation_score = normalize_syncopation_score(analysis.syncopation_index)

    suspicion_score = (entropy_score + variety_score + syncopation_score) / 3

    %{
      suspicion_score: suspicion_score,
      indicators: %{
        entropy_anomaly: entropy_score > 0.6,
        unusual_variety: variety_score > 0.7,
        suspicious_syncopation: syncopation_score > 0.8
      },
      analysis: analysis
    }
  end

  # Private helper functions

  # C major scale
  defp get_base_pitches(:c_major), do: [60, 62, 64, 65, 67, 69, 71, 72]
  # A minor scale
  defp get_base_pitches(:a_minor), do: [57, 59, 60, 62, 64, 65, 67, 69]
  # G major scale
  defp get_base_pitches(:g_major), do: [55, 57, 59, 60, 62, 64, 66, 67]
  defp get_base_pitches(_), do: [60, 62, 64, 65, 67, 69, 71, 72]

  defp calculate_average([]), do: 0.0

  defp calculate_average(values) do
    Enum.sum(values) / length(values)
  end

  defp calculate_rhythm_entropy([]), do: 0.0

  defp calculate_rhythm_entropy(durations) do
    frequencies = Enum.frequencies(durations)
    total = length(durations)

    frequencies
    |> Enum.reduce(0, fn {_duration, count}, acc ->
      probability = count / total
      acc - probability * :math.log2(probability)
    end)
  end

  defp calculate_syncopation(notes) do
    # Simplified syncopation measure: ratio of notes on weak beats
    # In 4/4 time, beats 2 and 4 are "weak"
    total = length(notes)

    if total == 0 do
      0.0
    else
      # Approximate by looking at note positions modulo 4
      weak_beat_notes =
        Enum.count(notes, fn note ->
          rem(Map.get(note, :position, 0), 4) in [1, 3]
        end)

      weak_beat_notes / total
    end
  end

  defp normalize_entropy_score(entropy) do
    # Natural music entropy typically 1.5-2.5 bits
    # Too low (< 1.0) or too high (> 3.0) is suspicious
    cond do
      # Very low entropy
      entropy < 1.0 -> 1.0 - entropy
      # Very high entropy
      entropy > 3.0 -> min((entropy - 2.5) / 2.0, 1.0)
      # Normal range
      true -> 0.0
    end
  end

  defp normalize_variety_score(variety, total_notes) do
    # Natural music uses 3-5 different durations typically
    variety_ratio = variety / max(total_notes, 1)

    cond do
      # Too many different durations
      variety_ratio > 0.8 -> 1.0
      # Too few different durations
      variety_ratio < 0.1 -> 0.8
      true -> 0.0
    end
  end

  defp normalize_syncopation_score(syncopation_index) do
    # Natural music has syncopation ratio around 0.3-0.6
    # Perfectly even (0.5) with high consistency suggests encoding
    if abs(syncopation_index - 0.5) < 0.05 do
      0.9
    else
      0.0
    end
  end
end
