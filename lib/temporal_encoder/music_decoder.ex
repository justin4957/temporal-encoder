defmodule TemporalEncoder.MusicDecoder do
  @moduledoc """
  Decodes text messages from musical structures.

  Reverses the encoding process by analyzing pitch sequences, rhythmic patterns,
  melodic intervals, and harmonic structures to extract hidden information.

  ## Decoding Strategies

  The decoder attempts multiple strategies based on the encoding mode:

  - **Pitch decoding**: Maps MIDI pitches back to characters
  - **Rhythm decoding**: Analyzes note durations for binary patterns
  - **Interval decoding**: Reconstructs message from melodic intervals
  - **Multi-layer decoding**: Combines all approaches

  ## Example

      iex> {:ok, midi_data} = MusicEncoder.encode("HELLO")
      iex> {:ok, decoded_text} = MusicDecoder.decode(midi_data)
      iex> decoded_text
      "HELLO"
  """

  alias TemporalEncoder.MusicEncoder.{PitchMapper, RhythmEncoder, MIDIGenerator}

  @doc """
  Decodes text from MIDI binary data.

  ## Options

  - `:encoding_mode` - Expected encoding mode (default: :auto_detect)
  - `:key` - Musical key used in encoding (default: :c_major)

  ## Examples

      iex> {:ok, text} = MusicDecoder.decode(midi_binary)
      iex> is_binary(text)
      true
  """
  def decode(midi_binary, options \\ []) when is_binary(midi_binary) do
    encoding_mode = Keyword.get(options, :encoding_mode, :auto_detect)
    key = Keyword.get(options, :key, :c_major)

    with {:ok, midi_events} <- MIDIGenerator.parse_midi(midi_binary),
         {:ok, notes} <- extract_melody_notes(midi_events),
         {:ok, decoded_mode} <- determine_encoding_mode(notes, encoding_mode),
         {:ok, text} <- decode_notes(notes, decoded_mode, key) do
      {:ok, text}
    end
  end

  @doc """
  Extracts the melody track from parsed MIDI events.

  Returns the note sequence from the primary melody track (typically track 0).
  """
  def extract_melody_notes(midi_events) do
    case midi_events.tracks do
      [] ->
        {:error, "No tracks found in MIDI data"}

      [melody_track | _rest] ->
        notes = events_to_notes(melody_track.events)
        {:ok, notes}
    end
  end

  @doc """
  Attempts to auto-detect the encoding mode from the note characteristics.

  Analyzes statistical properties to determine the most likely encoding method.
  """
  def determine_encoding_mode(_notes, mode) when mode != :auto_detect do
    {:ok, mode}
  end

  def determine_encoding_mode(notes, :auto_detect) do
    # Analyze patterns to guess encoding mode
    rhythm_analysis = RhythmEncoder.analyze_rhythm_patterns(notes)
    pitch_analysis = PitchMapper.analyze_pitch_distribution(notes)

    mode =
      cond do
        # High rhythm variety with binary-like patterns suggests rhythm encoding
        rhythm_analysis.duration_variety >= 2 and
            length(notes) >= 8 ->
          :rhythm

        # High pitch entropy with scale-based notes suggests pitch encoding
        pitch_analysis.entropy > 2.5 ->
          :pitch

        # Wide intervals suggest interval encoding
        has_wide_intervals?(notes) ->
          :interval

        # Default to multi-layer for complex patterns
        true ->
          :multi_layer
      end

    {:ok, mode}
  end

  @doc """
  Provides detailed analysis of encoded MIDI data.

  Useful for security research and understanding encoding characteristics.
  """
  def analyze(midi_binary, options \\ []) when is_binary(midi_binary) do
    _key = Keyword.get(options, :key, :c_major)

    with {:ok, midi_events} <- MIDIGenerator.parse_midi(midi_binary),
         {:ok, notes} <- extract_melody_notes(midi_events) do
      pitch_analysis = PitchMapper.analyze_pitch_distribution(notes)
      rhythm_analysis = RhythmEncoder.analyze_rhythm_patterns(notes)
      rhythm_detection = RhythmEncoder.detect_rhythm_encoding(notes)
      interval_analysis = analyze_intervals(notes)

      {:ok,
       %{
         note_count: length(notes),
         duration_beats: rhythm_analysis.total_duration,
         pitch_analysis: pitch_analysis,
         rhythm_analysis: rhythm_analysis,
         interval_analysis: interval_analysis,
         encoding_detection: %{
           rhythm_suspicion: rhythm_detection.suspicion_score,
           likely_modes: suggest_encoding_modes(notes),
           anomaly_indicators: rhythm_detection.indicators
         }
       }}
    end
  end

  # Private decoding functions

  defp decode_notes(notes, :pitch, key) do
    text =
      notes
      |> Enum.map(&PitchMapper.pitch_to_char(&1.pitch, key))
      |> Enum.join()

    {:ok, text}
  end

  defp decode_notes(notes, :rhythm, _key) do
    # Notes are grouped in 8-note chunks (8 bits per character)
    text =
      notes
      |> Enum.chunk_every(8)
      |> Enum.map(&RhythmEncoder.rhythm_sequence_to_char/1)
      |> Enum.join()

    {:ok, text}
  end

  defp decode_notes(notes, :interval, _key) do
    # Decode from intervals between notes
    text =
      notes
      |> Enum.map(& &1.pitch)
      |> intervals_to_text()

    {:ok, text}
  end

  defp decode_notes(notes, :multi_layer, key) do
    # Try pitch decoding first (primary layer)
    decode_notes(notes, :pitch, key)
  end

  defp events_to_notes(events) do
    # Group note_on and note_off events into notes with duration
    events
    |> Enum.filter(&(&1.type in [:note_on, :note_off]))
    |> Enum.sort_by(& &1.delta_time)
    |> group_note_events([])
  end

  defp group_note_events([], acc), do: Enum.reverse(acc)

  defp group_note_events([note_on | rest], acc) when note_on.type == :note_on do
    # Find corresponding note_off
    case find_note_off(rest, note_on.pitch, note_on.channel) do
      {note_off, remaining} ->
        duration = calculate_duration(note_on, note_off)

        note = %{
          pitch: note_on.pitch,
          duration: duration,
          velocity: note_on.velocity,
          position: note_on.delta_time
        }

        group_note_events(remaining, [note | acc])

      nil ->
        # No matching note_off found, skip this note
        group_note_events(rest, acc)
    end
  end

  defp group_note_events([_other | rest], acc) do
    # Skip non-note-on events
    group_note_events(rest, acc)
  end

  defp find_note_off(events, pitch, channel) do
    case Enum.split_while(events, fn event ->
           not (event.type == :note_off and event.pitch == pitch and event.channel == channel)
         end) do
      {before, [note_off | after_events]} ->
        {note_off, before ++ after_events}

      {_all, []} ->
        nil
    end
  end

  defp calculate_duration(note_on, note_off) do
    # Duration in ticks, convert to beats (assuming 480 ticks per beat)
    ticks_per_beat = 480
    tick_duration = note_off.delta_time - note_on.delta_time
    tick_duration / ticks_per_beat
  end

  defp intervals_to_text(pitches) do
    # Reconstruct ASCII values from intervals
    pitches
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [a, b] ->
      interval = abs(b - a)
      # Map interval back to ASCII range
      ascii_val = 32 + rem(interval * 7, 95)
      <<ascii_val>>
    end)
    |> Enum.join()
  end

  defp has_wide_intervals?(notes) do
    notes
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.any?(fn [a, b] -> abs(b.pitch - a.pitch) > 7 end)
  end

  defp analyze_intervals(notes) do
    intervals =
      notes
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [a, b] -> b.pitch - a.pitch end)

    %{
      mean_interval: calculate_mean(intervals),
      max_interval: Enum.max(intervals, fn -> 0 end),
      min_interval: Enum.min(intervals, fn -> 0 end),
      interval_distribution: Enum.frequencies(intervals)
    }
  end

  defp suggest_encoding_modes(notes) do
    rhythm_score = score_rhythm_encoding(notes)
    pitch_score = score_pitch_encoding(notes)
    interval_score = score_interval_encoding(notes)

    [
      {:rhythm, rhythm_score},
      {:pitch, pitch_score},
      {:interval, interval_score}
    ]
    |> Enum.sort_by(fn {_mode, score} -> score end, :desc)
    |> Enum.map(fn {mode, _score} -> mode end)
  end

  defp score_rhythm_encoding(notes) do
    analysis = RhythmEncoder.analyze_rhythm_patterns(notes)

    cond do
      analysis.duration_variety >= 2 and length(notes) >= 8 -> 0.8
      analysis.duration_variety >= 2 -> 0.5
      true -> 0.2
    end
  end

  defp score_pitch_encoding(notes) do
    analysis = PitchMapper.analyze_pitch_distribution(notes)

    cond do
      analysis.entropy > 3.0 -> 0.9
      analysis.entropy > 2.0 -> 0.7
      true -> 0.4
    end
  end

  defp score_interval_encoding(notes) do
    has_wide = has_wide_intervals?(notes)

    interval_variety =
      notes |> analyze_intervals() |> Map.get(:interval_distribution) |> map_size()

    cond do
      has_wide and interval_variety > 5 -> 0.7
      has_wide -> 0.5
      true -> 0.3
    end
  end

  defp calculate_mean([]), do: 0.0

  defp calculate_mean(values) do
    Enum.sum(values) / length(values)
  end
end
