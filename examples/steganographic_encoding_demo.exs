#!/usr/bin/env elixir

# Steganographic Encoding Demo
# Demonstrates encoding morse code timing into the structure of various data formats

defmodule SteganographicEncoder do
  @moduledoc """
  Encodes secret messages into the timing and structure of plausible-looking data.
  """

  @doc """
  Generates plausible base64-looking strings with timing patterns embedded.
  The length and character placement follow morse timing patterns.
  """
  def encode_in_base64_structure(message, opts \\ []) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, 100)

    {:ok, timestamps} = TemporalEncoder.encode(message, format: :relative, base_unit_ms: base_unit_ms)

    # Generate base64 chunks where chunk sizes and separators follow timing
    base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    intervals = calculate_intervals(timestamps)

    chunks = Enum.map(intervals, fn interval_ms ->
      # Convert interval to a chunk size (2-8 characters)
      units = round(interval_ms / base_unit_ms)
      chunk_size = min(max(units + 2, 2), 8)

      # Generate random base64 characters
      1..chunk_size
      |> Enum.map(fn _ -> Enum.random(String.graphemes(base64_chars)) end)
      |> Enum.join()
    end)

    encoded = Enum.join(chunks, "")
    # Add padding to look authentic
    padding = case rem(byte_size(encoded), 4) do
      0 -> ""
      n -> String.duplicate("=", 4 - n)
    end

    %{
      data: encoded <> padding,
      message: message,
      timestamps: timestamps,
      format: "base64",
      note: "Timing encoded in chunk boundaries and character distribution"
    }
  end

  @doc """
  Generates hex dump output with timing encoded in byte groupings and spacing.
  """
  def encode_in_hex_dump(message, opts \\ []) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, 100)

    {:ok, timestamps} = TemporalEncoder.encode(message, format: :relative, base_unit_ms: base_unit_ms)
    intervals = calculate_intervals(timestamps)

    # Generate hex bytes where grouping follows timing patterns
    lines = []
    byte_position = 0

    lines = Enum.reduce(intervals, [], fn interval_ms, acc ->
      units = round(interval_ms / base_unit_ms)
      # Number of bytes in this group (2-6 bytes per timing unit)
      byte_count = min(max(units * 2, 2), 16)

      # Generate random hex bytes
      hex_bytes = 1..byte_count
      |> Enum.map(fn _ ->
        byte = :rand.uniform(256) - 1
        String.pad_leading(Integer.to_string(byte, 16), 2, "0")
      end)
      |> Enum.join(" ")

      # Format as hex dump line
      offset = String.pad_leading(Integer.to_string(byte_position, 16), 8, "0")
      line = "#{offset}  #{hex_bytes}"

      byte_position = byte_position + byte_count
      [line | acc]
    end)
    |> Enum.reverse()

    %{
      data: Enum.join(lines, "\n"),
      message: message,
      timestamps: timestamps,
      format: "hexdump",
      note: "Timing encoded in byte grouping patterns per line"
    }
  end

  @doc """
  Generates UTF-8 text with timing encoded in word lengths and punctuation placement.
  Uses a simple substitution cipher overlaid on the structure.
  """
  def encode_in_utf8_text(message, opts \\ []) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, 100)

    {:ok, timestamps} = TemporalEncoder.encode(message, format: :relative, base_unit_ms: base_unit_ms)
    {:ok, morse_patterns} = TemporalEncoder.MorseEncoder.encode(message)

    intervals = calculate_intervals(timestamps)

    # Word pool for generating plausible text
    word_pool = [
      "data", "system", "process", "network", "server", "client", "request",
      "response", "protocol", "packet", "header", "payload", "connection",
      "secure", "encrypted", "verified", "authenticated", "authorized",
      "buffer", "cache", "memory", "storage", "database", "query", "index",
      "algorithm", "function", "method", "class", "object", "interface"
    ]

    # Generate text where word lengths follow timing
    words = Enum.map(intervals, fn interval_ms ->
      units = round(interval_ms / base_unit_ms)
      # Select word with length related to timing units
      target_length = min(max(units + 2, 3), 12)

      # Find word closest to target length
      Enum.min_by(word_pool, fn word ->
        abs(String.length(word) - target_length)
      end)
    end)

    # Add punctuation based on morse patterns (/ = period, otherwise comma/nothing)
    text_with_punctuation = morse_patterns
    |> Enum.zip(words)
    |> Enum.map_join(" ", fn {morse_pattern, word} ->
      cond do
        morse_pattern == "/" -> word <> "."
        String.length(morse_pattern) > 3 -> word <> ","
        true -> word
      end
    end)

    # Apply simple Caesar cipher shift to actual message characters
    cipher_key = message
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map(fn {char, idx} -> "#{char}→#{idx}" end)
    |> Enum.join(", ")

    %{
      data: text_with_punctuation,
      message: message,
      timestamps: timestamps,
      format: "utf8_text",
      cipher_key: cipher_key,
      morse: Enum.join(morse_patterns, " "),
      note: "Timing in word lengths, morse in punctuation, cipher in structure"
    }
  end

  @doc """
  Multi-layer encoding: combines all techniques with interleaved data.
  """
  def encode_multilayer(message, opts \\ []) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, 100)

    {:ok, timestamps} = TemporalEncoder.encode(message, format: :relative, base_unit_ms: base_unit_ms)
    {:ok, morse_patterns} = TemporalEncoder.MorseEncoder.encode(message)

    # Layer 1: Visual data (looks like API response)
    visual_layer = generate_api_response(message)

    # Layer 2: Timing in the "response time" headers
    timing_layer = timestamps
    |> Enum.map(fn ts -> "#{ts}ms" end)
    |> Enum.join(", ")

    # Layer 3: Morse as HTTP status code patterns
    status_codes = morse_patterns
    |> Enum.map(fn pattern ->
      cond do
        pattern == "/" -> 301  # Redirect for word boundary
        String.contains?(pattern, "-") -> 200  # OK for dah
        true -> 204  # No Content for dit
      end
    end)

    # Layer 4: ROT13 cipher applied to message
    rot13_message = apply_rot13(message)

    %{
      visual: visual_layer,
      timing_header: "X-Response-Times: #{timing_layer}",
      status_sequence: status_codes,
      morse_code: Enum.join(morse_patterns, " "),
      cipher: rot13_message,
      original: message,
      format: "multilayer",
      note: "Visual: API response | Timing: Response headers | Morse: Status codes | Cipher: ROT13"
    }
  end

  # Helper functions

  defp calculate_intervals([]), do: []
  defp calculate_intervals([_]), do: []
  defp calculate_intervals(timestamps) do
    timestamps
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [a, b] -> b - a end)
  end

  defp generate_api_response(message) do
    ~s"""
    {
      "status": "success",
      "data": {
        "id": "#{generate_id()}",
        "message": "Operation completed",
        "metadata": {
          "length": #{String.length(message)},
          "timestamp": #{System.system_time(:millisecond)}
        }
      }
    }
    """
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8)
    |> Base.encode16(case: :lower)
  end

  defp apply_rot13(text) do
    text
    |> String.graphemes()
    |> Enum.map(fn char ->
      cond do
        char >= "A" and char <= "Z" ->
          <<base>> = "A"
          offset = :binary.first(char) - base
          new_offset = rem(offset + 13, 26)
          <<base + new_offset>>

        char >= "a" and char <= "z" ->
          <<base>> = "a"
          offset = :binary.first(char) - base
          new_offset = rem(offset + 13, 26)
          <<base + new_offset>>

        true -> char
      end
    end)
    |> Enum.join()
  end
end

# Demo execution

IO.puts("\n╔═══════════════════════════════════════════════════════════╗")
IO.puts("║  STEGANOGRAPHIC ENCODING DEMONSTRATION                   ║")
IO.puts("║  Hiding Messages in Plain Sight                          ║")
IO.puts("╚═══════════════════════════════════════════════════════════╝\n")

# Secret messages to encode
messages = [
  "HIDE",
  "SECRET MESSAGE",
  "DEAD DROP AT NOON"
]

Enum.each(messages, fn message ->
  IO.puts("\n" <> String.duplicate("═", 60))
  IO.puts("SECRET MESSAGE: \"#{message}\"")
  IO.puts(String.duplicate("═", 60))

  # Technique 1: Base64 Structure
  IO.puts("\n▶ TECHNIQUE 1: Base64 Structural Encoding")
  IO.puts("━" <> String.duplicate("─", 58))

  result1 = SteganographicEncoder.encode_in_base64_structure(message, base_unit_ms: 50)
  IO.puts("Encoded data (appears as base64):")
  IO.puts("  #{result1.data}")
  IO.puts("\nHow it works:")
  IO.puts("  • Chunk sizes: #{inspect(result1.timestamps |> Enum.take(5))}... (first 5 timestamps)")
  IO.puts("  • #{result1.note}")

  # Technique 2: Hex Dump
  IO.puts("\n▶ TECHNIQUE 2: Hex Dump Pattern Encoding")
  IO.puts("━" <> String.duplicate("─", 58))

  result2 = SteganographicEncoder.encode_in_hex_dump(message, base_unit_ms: 50)
  IO.puts("Encoded data (appears as hex dump):")
  result2.data
  |> String.split("\n")
  |> Enum.take(5)
  |> Enum.each(fn line -> IO.puts("  #{line}") end)
  if length(String.split(result2.data, "\n")) > 5 do
    IO.puts("  ... (#{length(String.split(result2.data, "\n")) - 5} more lines)")
  end
  IO.puts("\nHow it works:")
  IO.puts("  • #{result2.note}")

  # Technique 3: UTF-8 Text with Word Lengths
  IO.puts("\n▶ TECHNIQUE 3: UTF-8 Text with Embedded Patterns")
  IO.puts("━" <> String.duplicate("─", 58))

  result3 = SteganographicEncoder.encode_in_utf8_text(message, base_unit_ms: 50)
  IO.puts("Encoded data (appears as technical text):")
  IO.puts("  #{result3.data}")
  IO.puts("\nHow it works:")
  IO.puts("  • Morse code: #{result3.morse}")
  IO.puts("  • Cipher mapping: #{result3.cipher_key}")
  IO.puts("  • #{result3.note}")

  # Technique 4: Multi-layer
  if String.length(message) < 20 do  # Keep output manageable
    IO.puts("\n▶ TECHNIQUE 4: Multi-Layer Encoding")
    IO.puts("━" <> String.duplicate("─", 58))

    result4 = SteganographicEncoder.encode_multilayer(message, base_unit_ms: 50)
    IO.puts("Layer 1 - Visual (API Response):")
    IO.puts(String.replace(result4.visual, "\n", "\n  "))
    IO.puts("\nLayer 2 - Timing Header:")
    IO.puts("  #{result4.timing_header}")
    IO.puts("\nLayer 3 - Status Code Sequence:")
    IO.puts("  #{inspect(result4.status_sequence)}")
    IO.puts("\nLayer 4 - ROT13 Cipher:")
    IO.puts("  Original: #{result4.original}")
    IO.puts("  Encoded:  #{result4.cipher}")
    IO.puts("\nMorse Code:")
    IO.puts("  #{result4.morse_code}")
    IO.puts("\nNote: #{result4.note}")
  end
end)

# Demonstrate decoding workflow
IO.puts("\n\n" <> String.duplicate("═", 60))
IO.puts("DECODING DEMONSTRATION")
IO.puts(String.duplicate("═", 60))

message = "SOS"
IO.puts("\nOriginal message: \"#{message}\"")

# Encode using base64 structure
encoded = SteganographicEncoder.encode_in_base64_structure(message, base_unit_ms: 100)
IO.puts("\nEncoded in base64 structure:")
IO.puts("  #{encoded.data}")
IO.puts("\nExtracted timestamps:")
IO.puts("  #{inspect(encoded.timestamps)}")

# Decode back
{:ok, decoded} = TemporalEncoder.decode(encoded.timestamps, base_unit_ms: 100, auto_detect_unit: false)
IO.puts("\nDecoded message: \"#{decoded}\"")
IO.puts("✓ Match: #{decoded == message}")

IO.puts("\n" <> String.duplicate("═", 60))
IO.puts("KEY INSIGHTS")
IO.puts(String.duplicate("═", 60))

IO.puts("""

1. BASE64 STRUCTURE ENCODING
   • Timing embedded in chunk sizes and boundaries
   • Looks like legitimate base64 encoded data
   • Resistant to casual inspection

2. HEX DUMP PATTERN ENCODING
   • Timing in byte grouping patterns
   • Appears as normal memory dump or packet capture
   • Analysis requires recognizing non-random groupings

3. UTF-8 TEXT ENCODING
   • Timing in word lengths and punctuation
   • Multiple layers: word choice, punctuation, structure
   • Reads as plausible technical documentation

4. MULTI-LAYER ENCODING
   • Combines visual, timing, and cipher techniques
   • Each layer provides partial information
   • Requires full decode pipeline to extract message
   • Maximum steganographic effect

DETECTION CHALLENGES:
• All formats appear syntactically valid
• Statistical analysis required to detect patterns
• Multiple encoding layers increase complexity
• Timing analysis needed to extract full message
""")

IO.puts("\n╔═══════════════════════════════════════════════════════════╗")
IO.puts("║  Demo Complete - Message Hidden in Multiple Formats      ║")
IO.puts("╚═══════════════════════════════════════════════════════════╝\n")
