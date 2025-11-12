defmodule TemporalEncoder.MusicEncoder do
  @moduledoc """
  Encodes text messages into musical structures using multiple steganographic layers.

  This module demonstrates covert communication through music by encoding information
  in pitch sequences, rhythmic patterns, melodic intervals, and harmonic structures.

  ## Encoding Layers

  ### Layer 1: Pitch Encoding
  Maps characters to MIDI note numbers using a character-to-pitch mapping.
  - A-Z: Notes in C major scale (C4-B5)
  - 0-9: Notes in C6 octave
  - Space: Rest
  - Punctuation: Chromatic notes

  ### Layer 2: Rhythm Encoding
  Encodes binary representation of ASCII values in note durations:
  - Short notes (eighth notes): 0 bit
  - Long notes (quarter notes): 1 bit

  ### Layer 3: Interval Encoding
  The melodic interval between consecutive notes encodes information:
  - Minor intervals (1-3 semitones): Low-value characters
  - Major intervals (4-7 semitones): Mid-value characters
  - Large intervals (8+ semitones): High-value characters

  ### Layer 4: Harmonic Context
  Chord progressions and harmonic backing provide additional encoding dimensions
  and make the music sound more natural to avoid detection.

  ## Example

      iex> {:ok, midi_data} = MusicEncoder.encode("HELLO")
      iex> is_binary(midi_data)
      true
  """

  alias TemporalEncoder.MusicEncoder.{PitchMapper, RhythmEncoder, MIDIGenerator}

  @doc """
  Encodes text into MIDI binary data.

  ## Options

  - `:tempo` - BPM (default: 120)
  - `:key` - Musical key (default: :c_major)
  - `:encoding_mode` - :pitch, :rhythm, :interval, or :multi_layer (default: :multi_layer)
  - `:add_harmony` - Add harmonic backing for naturalness (default: true)

  ## Examples

      iex> {:ok, midi} = MusicEncoder.encode("HELLO WORLD")
      iex> byte_size(midi) > 0
      true
  """
  def encode(text, options \\ []) do
    tempo = Keyword.get(options, :tempo, 120)
    key = Keyword.get(options, :key, :c_major)
    encoding_mode = Keyword.get(options, :encoding_mode, :multi_layer)
    add_harmony = Keyword.get(options, :add_harmony, true)

    with {:ok, note_sequence} <- encode_to_notes(text, encoding_mode, key),
         {:ok, harmony} <- maybe_generate_harmony(note_sequence, add_harmony, key),
         {:ok, midi_events} <- MIDIGenerator.generate_midi_events(note_sequence, harmony, tempo) do
      {:ok, MIDIGenerator.serialize_to_midi(midi_events, tempo)}
    end
  end

  @doc """
  Returns information about the encoded music without generating MIDI.

  Useful for analysis and understanding the encoding.
  """
  def encoding_info(text, options \\ []) do
    encoding_mode = Keyword.get(options, :encoding_mode, :multi_layer)
    key = Keyword.get(options, :key, :c_major)

    case encode_to_notes(text, encoding_mode, key) do
      {:ok, note_sequence} ->
        {:ok,
         %{
           character_count: String.length(text),
           note_count: length(note_sequence),
           duration_beats: calculate_duration(note_sequence),
           pitch_range: analyze_pitch_range(note_sequence),
           interval_distribution: analyze_intervals(note_sequence),
           encoding_mode: encoding_mode,
           musical_key: key
         }}

      error ->
        error
    end
  end

  # Private functions

  defp encode_to_notes(text, :pitch, key) do
    notes =
      text
      |> String.graphemes()
      |> Enum.map(&PitchMapper.char_to_pitch(&1, key))

    {:ok, notes}
  end

  defp encode_to_notes(text, :rhythm, key) do
    notes =
      text
      |> String.graphemes()
      |> Enum.flat_map(&RhythmEncoder.char_to_rhythm_sequence(&1, key))

    {:ok, notes}
  end

  defp encode_to_notes(text, :interval, key) do
    notes =
      text
      |> String.to_charlist()
      |> encode_via_intervals(key)

    {:ok, notes}
  end

  defp encode_to_notes(text, :multi_layer, key) do
    # Combines all encoding methods for maximum information density
    notes =
      text
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.flat_map(fn {char, idx} ->
        # Primary: pitch encoding
        base_pitch = PitchMapper.char_to_pitch(char, key)

        # Secondary: rhythm encoding (duration)
        duration = RhythmEncoder.char_to_duration(char)

        # Tertiary: add interval hint via velocity
        velocity = char_to_velocity(char)

        [%{pitch: base_pitch, duration: duration, velocity: velocity, position: idx}]
      end)

    {:ok, notes}
  end

  defp encode_via_intervals(charlist, _key) do
    # C4
    base_pitch = 60

    {notes, _last_pitch} =
      Enum.map_reduce(charlist, base_pitch, fn ascii_val, last_pitch ->
        # Use ASCII value to determine interval
        interval = rem(ascii_val, 12)
        next_pitch = last_pitch + interval

        # Keep in reasonable range
        pitch =
          cond do
            next_pitch > 84 -> next_pitch - 12
            next_pitch < 48 -> next_pitch + 12
            true -> next_pitch
          end

        note = %{pitch: pitch, duration: 0.5, velocity: 80, position: 0}
        {note, pitch}
      end)

    notes
  end

  defp maybe_generate_harmony(_notes, false, _key), do: {:ok, []}

  defp maybe_generate_harmony(notes, true, key) do
    # Generate simple chord progression that follows the melody
    harmony =
      notes
      |> Enum.chunk_every(4)
      |> Enum.with_index()
      |> Enum.flat_map(fn {_chunk, idx} ->
        chord = generate_chord_for_section(idx, key)

        Enum.map(chord, fn pitch ->
          %{pitch: pitch, duration: 2.0, velocity: 50, position: idx * 4}
        end)
      end)

    {:ok, harmony}
  end

  defp generate_chord_for_section(section_idx, key) do
    # Simple I-IV-V-I progression in C major
    root = get_root_note(key)

    chord_root =
      case rem(section_idx, 4) do
        # I
        0 -> root
        # IV
        1 -> root + 5
        # V
        2 -> root + 7
        # I
        3 -> root
      end

    # Triad: root, major third, perfect fifth
    [chord_root, chord_root + 4, chord_root + 7]
  end

  defp calculate_duration(notes) do
    Enum.reduce(notes, 0, fn note, acc -> acc + Map.get(note, :duration, 0.5) end)
  end

  defp analyze_pitch_range(notes) when is_list(notes) and length(notes) > 0 do
    pitches =
      notes
      |> Enum.map(fn note -> Map.get(note, :pitch, 0) end)
      |> Enum.filter(&is_integer/1)
      |> Enum.filter(&(&1 > 0))

    if Enum.empty?(pitches) do
      %{lowest: 0, highest: 0, span_semitones: 0}
    else
      lowest = Enum.min(pitches)
      highest = Enum.max(pitches)

      %{
        lowest: lowest,
        highest: highest,
        span_semitones: highest - lowest
      }
    end
  end

  defp analyze_pitch_range(_), do: %{lowest: 0, highest: 0, span_semitones: 0}

  defp analyze_intervals(notes) when is_list(notes) do
    notes
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [a, b] ->
      abs(Map.get(b, :pitch, 0) - Map.get(a, :pitch, 0))
    end)
    |> Enum.frequencies()
  end

  defp analyze_intervals(_), do: %{}

  defp char_to_velocity(char) do
    # Map character to MIDI velocity (40-100 range for naturalness)
    base_vel = 60
    char_val = :binary.first(char)
    base_vel + rem(char_val, 40)
  end

  defp get_scale(:c_major), do: [0, 2, 4, 5, 7, 9, 11]
  defp get_scale(:a_minor), do: [0, 2, 3, 5, 7, 8, 10]
  defp get_scale(:g_major), do: [0, 2, 4, 5, 7, 9, 11]
  defp get_scale(_), do: [0, 2, 4, 5, 7, 9, 11]

  # C3
  defp get_root_note(:c_major), do: 48
  # A2
  defp get_root_note(:a_minor), do: 45
  # G2
  defp get_root_note(:g_major), do: 43
  defp get_root_note(_), do: 48
end
