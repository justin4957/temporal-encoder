defmodule TemporalEncoder.MusicEncoder.PitchMapper do
  @moduledoc """
  Maps characters to musical pitches using various encoding schemes.

  Provides deterministic character-to-pitch mappings that create musically
  plausible note sequences while encoding information.
  """

  @doc """
  Maps a character to a MIDI pitch number within a given key.

  Uses the character's position in the supported character set to determine
  the pitch within the scale.

  ## Examples

      iex> PitchMapper.char_to_pitch("A", :c_major)
      %{pitch: 60, duration: 0.5, velocity: 80, position: 0}

      iex> PitchMapper.char_to_pitch(" ", :c_major)
      %{pitch: 0, duration: 0.25, velocity: 0, position: 0}  # Rest
  """
  def char_to_pitch(char, key \\ :c_major)

  def char_to_pitch(" ", _key) do
    # Space = rest
    %{pitch: 0, duration: 0.25, velocity: 0, position: 0}
  end

  def char_to_pitch(char, key) when is_binary(char) do
    scale = get_scale_notes(key)
    char_upper = String.upcase(char)

    pitch =
      cond do
        # Letters A-Z
        char_upper >= "A" and char_upper <= "Z" ->
          index = :binary.first(char_upper) - ?A
          octave = div(index, 7)
          scale_degree = rem(index, 7)
          # C4
          base = 60
          base + octave * 12 + Enum.at(scale, scale_degree)

        # Digits 0-9
        char >= "0" and char <= "9" ->
          digit = :binary.first(char) - ?0
          # C6 + offset
          72 + digit

        # Punctuation - chromatic notes
        true ->
          # Use ASCII value to generate pitch
          ascii_val = :binary.first(char)
          48 + rem(ascii_val, 36)
      end

    %{pitch: pitch, duration: 0.5, velocity: 80, position: 0}
  end

  @doc """
  Reverse mapping: finds the character that would encode to a given pitch.

  Used for decoding. Returns the most likely character based on pitch.
  """
  def pitch_to_char(pitch, key \\ :c_major) when is_integer(pitch) do
    cond do
      pitch == 0 ->
        " "

      pitch >= 72 and pitch <= 81 ->
        # Digit range
        Integer.to_string(pitch - 72)

      pitch >= 48 and pitch <= 95 ->
        # Letter range
        scale = get_scale_notes(key)
        relative_pitch = pitch - 60

        octave = div(relative_pitch, 12)
        pitch_in_octave = rem(relative_pitch, 12)

        # Find closest scale degree
        scale_degree =
          scale
          |> Enum.with_index()
          |> Enum.min_by(fn {note, _idx} -> abs(note - pitch_in_octave) end)
          |> elem(1)

        char_index = octave * 7 + scale_degree

        if char_index >= 0 and char_index < 26 do
          <<?A + char_index::utf8>>
        else
          "?"
        end

      true ->
        # Punctuation or unknown
        "?"
    end
  end

  @doc """
  Returns the scale notes (as semitone offsets) for a given key.
  """
  def get_scale_notes(:c_major), do: [0, 2, 4, 5, 7, 9, 11]
  def get_scale_notes(:a_minor), do: [0, 2, 3, 5, 7, 8, 10]
  def get_scale_notes(:g_major), do: [0, 2, 4, 5, 7, 9, 11]
  def get_scale_notes(:d_major), do: [0, 2, 4, 6, 7, 9, 11]
  def get_scale_notes(_), do: [0, 2, 4, 5, 7, 9, 11]

  @doc """
  Maps a MIDI pitch number to a human-readable note name.

  ## Examples

      iex> PitchMapper.pitch_to_note_name(60)
      "C4"

      iex> PitchMapper.pitch_to_note_name(69)
      "A4"
  """
  def pitch_to_note_name(pitch) when is_integer(pitch) do
    note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    octave = div(pitch, 12) - 1
    note_index = rem(pitch, 12)
    note_name = Enum.at(note_names, note_index)

    "#{note_name}#{octave}"
  end

  @doc """
  Analyzes a sequence of pitches for statistical patterns.

  Used for detection analysis - natural music has certain statistical properties,
  while encoded data may have different distributions.
  """
  def analyze_pitch_distribution(pitches) when is_list(pitches) do
    pitch_values = Enum.map(pitches, & &1.pitch)

    %{
      mean: calculate_mean(pitch_values),
      median: calculate_median(pitch_values),
      std_dev: calculate_std_dev(pitch_values),
      entropy: calculate_entropy(pitch_values),
      pitch_class_distribution: analyze_pitch_classes(pitch_values)
    }
  end

  # Private helper functions

  defp calculate_mean([]), do: 0.0

  defp calculate_mean(values) do
    Enum.sum(values) / length(values)
  end

  defp calculate_median([]), do: 0.0

  defp calculate_median(values) do
    sorted = Enum.sort(values)
    len = length(sorted)
    mid = div(len, 2)

    if rem(len, 2) == 0 do
      (Enum.at(sorted, mid - 1) + Enum.at(sorted, mid)) / 2
    else
      Enum.at(sorted, mid) * 1.0
    end
  end

  defp calculate_std_dev([]), do: 0.0

  defp calculate_std_dev(values) do
    mean = calculate_mean(values)

    variance =
      Enum.reduce(values, 0, fn v, acc -> acc + :math.pow(v - mean, 2) end) / length(values)

    :math.sqrt(variance)
  end

  defp calculate_entropy([]), do: 0.0

  defp calculate_entropy(values) do
    frequencies = Enum.frequencies(values)
    total = length(values)

    frequencies
    |> Enum.reduce(0, fn {_val, count}, acc ->
      probability = count / total
      acc - probability * :math.log2(probability)
    end)
  end

  defp analyze_pitch_classes(pitches) do
    pitches
    |> Enum.map(&rem(&1, 12))
    |> Enum.frequencies()
    |> Enum.sort()
  end
end
