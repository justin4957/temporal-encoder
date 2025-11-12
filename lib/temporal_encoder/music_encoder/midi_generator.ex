defmodule TemporalEncoder.MusicEncoder.MIDIGenerator do
  @moduledoc """
  Generates MIDI binary data from note sequences.

  Creates standard MIDI format 1 files that can be played by any MIDI player
  or imported into music software for analysis.
  """

  import Bitwise

  @doc """
  Generates MIDI events from note and harmony sequences.

  Returns a list of MIDI events with timing information.
  """
  def generate_midi_events(notes, harmony, tempo) do
    ticks_per_beat = 480
    ms_per_beat = 60_000 / tempo
    ms_per_tick = ms_per_beat / ticks_per_beat

    # Combine melody and harmony tracks
    melody_events = notes_to_events(notes, 0, ticks_per_beat)
    harmony_events = notes_to_events(harmony, 1, ticks_per_beat)

    events = %{
      tempo: tempo,
      ticks_per_beat: ticks_per_beat,
      tracks: [
        %{channel: 0, events: melody_events},
        %{channel: 1, events: harmony_events}
      ]
    }

    {:ok, events}
  end

  @doc """
  Serializes MIDI events to standard MIDI file format (SMF).

  Creates a binary MIDI file that can be saved and played.
  """
  def serialize_to_midi(midi_events, tempo) do
    ticks_per_beat = midi_events.ticks_per_beat

    # MIDI Header Chunk
    header = create_midi_header(length(midi_events.tracks), ticks_per_beat)

    # Track Chunks
    tracks =
      midi_events.tracks
      |> Enum.map(&create_track_chunk(&1, tempo, ticks_per_beat))
      |> Enum.join()

    header <> tracks
  end

  @doc """
  Parses MIDI binary data back to event structure.

  Used for decoding and analysis.
  """
  def parse_midi(midi_binary) when is_binary(midi_binary) do
    with {:ok, header, rest} <- parse_header(midi_binary),
         {:ok, tracks} <- parse_tracks(rest, header.num_tracks) do
      {:ok,
       %{
         format: header.format,
         num_tracks: header.num_tracks,
         ticks_per_beat: header.division,
         tracks: tracks
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions for MIDI generation

  defp notes_to_events(notes, channel, ticks_per_beat) do
    {events, _current_tick} =
      Enum.reduce(notes, {[], 0}, fn note, {events_acc, tick} ->
        pitch = note.pitch
        duration = note.duration
        velocity = Map.get(note, :velocity, 80)

        # Skip rests (pitch = 0)
        if pitch == 0 do
          duration_ticks = round(duration * ticks_per_beat)
          {events_acc, tick + duration_ticks}
        else
          duration_ticks = round(duration * ticks_per_beat)

          note_on = %{
            type: :note_on,
            tick: tick,
            channel: channel,
            pitch: pitch,
            velocity: velocity
          }

          note_off = %{
            type: :note_off,
            tick: tick + duration_ticks,
            channel: channel,
            pitch: pitch,
            velocity: 0
          }

          {[note_off, note_on | events_acc], tick + duration_ticks}
        end
      end)

    # Sort by tick time and reverse (they were accumulated in reverse)
    events
    |> Enum.reverse()
    |> Enum.sort_by(& &1.tick)
  end

  defp create_midi_header(num_tracks, ticks_per_beat) do
    # Format 1: multiple tracks, synchronous
    format = 1

    # MThd chunk
    <<"MThd", 0, 0, 0, 6, format::16, num_tracks::16, ticks_per_beat::16>>
  end

  defp create_track_chunk(track, tempo, ticks_per_beat) do
    # Set tempo event (in track 0, but we'll add it to all for simplicity)
    microseconds_per_quarter = div(60_000_000, tempo)

    tempo_event = <<
      0,
      # Delta time
      0xFF,
      0x51,
      0x03,
      microseconds_per_quarter::24
    >>

    # Convert events to MIDI messages
    midi_messages =
      track.events
      |> Enum.chunk_every(2)
      |> Enum.flat_map(fn
        [note_on, note_off] ->
          delta_on = encode_variable_length(note_on.tick)
          delta_off = encode_variable_length(note_off.tick - note_on.tick)

          [
            delta_on <>
              <<0x90 + track.channel, note_on.pitch, note_on.velocity>>,
            delta_off <>
              <<0x80 + track.channel, note_off.pitch, 0>>
          ]

        [single_event] ->
          # Handle odd event
          delta = encode_variable_length(single_event.tick)
          [delta <> <<0x80 + track.channel, single_event.pitch, 0>>]
      end)
      |> Enum.join()

    # End of track event
    end_of_track = <<0, 0xFF, 0x2F, 0>>

    track_data = tempo_event <> midi_messages <> end_of_track
    track_length = byte_size(track_data)

    # MTrk chunk
    <<"MTrk", track_length::32, track_data::binary>>
  end

  defp encode_variable_length(value) when value < 0x80 do
    <<value>>
  end

  defp encode_variable_length(value) do
    # Variable-length quantity encoding
    bytes = []
    bytes = encode_vlq(value, bytes)
    :binary.list_to_bin(bytes)
  end

  defp encode_vlq(0, []), do: [0]
  defp encode_vlq(0, acc), do: Enum.reverse(acc)

  defp encode_vlq(value, []) do
    byte = value &&& 0x7F
    encode_vlq(value >>> 7, [byte])
  end

  defp encode_vlq(value, acc) do
    byte = (value &&& 0x7F) ||| 0x80
    encode_vlq(value >>> 7, [byte | acc])
  end

  # Private functions for MIDI parsing

  defp parse_header(<<
         "MThd",
         0,
         0,
         0,
         6,
         format::16,
         num_tracks::16,
         division::16,
         rest::binary
       >>) do
    header = %{
      format: format,
      num_tracks: num_tracks,
      division: division
    }

    {:ok, header, rest}
  end

  defp parse_header(_), do: {:error, "Invalid MIDI header"}

  defp parse_tracks(binary, num_tracks) do
    parse_tracks_acc(binary, num_tracks, [])
  end

  defp parse_tracks_acc(_binary, 0, acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp parse_tracks_acc(binary, remaining, acc) do
    case parse_track(binary) do
      {:ok, track, rest} ->
        parse_tracks_acc(rest, remaining - 1, [track | acc])

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_track(<<"MTrk", length::32, track_data::binary-size(length), rest::binary>>) do
    events = parse_track_events(track_data, 0, [])

    track = %{
      events: events,
      length: length
    }

    {:ok, track, rest}
  end

  defp parse_track(_), do: {:error, "Invalid track chunk"}

  defp parse_track_events(<<>>, _tick, acc), do: Enum.reverse(acc)

  defp parse_track_events(binary, current_tick, acc) do
    case parse_event(binary, current_tick) do
      {:ok, event, rest} ->
        new_tick = current_tick + event.delta_time
        parse_track_events(rest, new_tick, [event | acc])

      {:error, _reason} ->
        # End parsing on error
        Enum.reverse(acc)
    end
  end

  defp parse_event(binary, current_tick) do
    with {:ok, delta_time, rest} <- decode_variable_length(binary),
         {:ok, event_data, remaining} <- parse_midi_event(rest) do
      event = Map.put(event_data, :delta_time, delta_time)
      {:ok, event, remaining}
    else
      error -> error
    end
  end

  defp decode_variable_length(binary) do
    decode_vlq(binary, 0, 0)
  end

  defp decode_vlq(<<byte, rest::binary>>, value, _count) when byte < 0x80 do
    final_value = (value <<< 7) + byte
    {:ok, final_value, rest}
  end

  defp decode_vlq(<<byte, rest::binary>>, value, count) when count < 4 do
    new_value = (value <<< 7) + (byte &&& 0x7F)
    decode_vlq(rest, new_value, count + 1)
  end

  defp decode_vlq(_, _, _), do: {:error, "Invalid variable length quantity"}

  defp parse_midi_event(<<status, data::binary>>) when status >= 0x80 do
    case status &&& 0xF0 do
      0x80 ->
        # Note off
        <<pitch, velocity, rest::binary>> = data

        {:ok, %{type: :note_off, pitch: pitch, velocity: velocity, channel: status &&& 0x0F},
         rest}

      0x90 ->
        # Note on
        <<pitch, velocity, rest::binary>> = data
        {:ok, %{type: :note_on, pitch: pitch, velocity: velocity, channel: status &&& 0x0F}, rest}

      0xFF ->
        # Meta event
        <<type, length, rest::binary>> = data
        <<meta_data::binary-size(length), remaining::binary>> = rest
        {:ok, %{type: :meta, meta_type: type, data: meta_data}, remaining}

      _ ->
        {:error, "Unsupported MIDI event"}
    end
  end

  defp parse_midi_event(_), do: {:error, "Invalid MIDI event"}
end
