#!/usr/bin/env elixir

# Simple Music Encoding Demonstration
# Educational & Research Purposes Only

IO.puts("""

╔═══════════════════════════════════════════════════════════════════════╗
║                   MUSIC STEGANOGRAPHY DEMO                            ║
║                   Educational & Research Purposes Only                ║
╚═══════════════════════════════════════════════════════════════════════╝

This demonstrates encoding benign messages into musical MIDI files.

""")

alias TemporalEncoder.{MusicEncoder, MusicDecoder, MusicAnalyzer}

# Example messages
messages = [
  "HELLO",
  "MEET AT NOON",
  "STATUS OK"
]

Enum.each(messages, fn message ->
  IO.puts("\n" <> String.duplicate("=", 75))
  IO.puts("Message: \"#{message}\"")
  IO.puts(String.duplicate("=", 75))

  # Encode
  {:ok, midi_data} =
    MusicEncoder.encode(message,
      encoding_mode: :multi_layer,
      add_harmony: true,
      tempo: 120,
      key: :c_major
    )

  IO.puts("✓ Encoded to MIDI: #{byte_size(midi_data)} bytes")

  # Save to file
  filename = "/tmp/#{String.replace(message, " ", "_")}.mid"
  File.write!(filename, midi_data)
  IO.puts("✓ Saved to: #{filename}")

  # Decode
  {:ok, decoded} = MusicDecoder.decode(midi_data, encoding_mode: :multi_layer)
  IO.puts("✓ Decoded: \"#{decoded}\"")

  match = if decoded == message, do: "✓ SUCCESS", else: "✗ MISMATCH"
  IO.puts("Verification: #{match}")

  # Analyze
  {:ok, analysis} = MusicAnalyzer.analyze_file(midi_data)

  IO.puts("\nForensic Analysis:")
  IO.puts("  Suspicion Score: #{Float.round(analysis.overall_suspicion_score, 3)} / 1.0")
  IO.puts("  Risk Level: #{analysis.risk_level |> Atom.to_string() |> String.upcase()}")

  if length(analysis.anomalies) > 0 do
    IO.puts("  Anomalies:")

    Enum.each(analysis.anomalies, fn anomaly ->
      IO.puts("    - #{anomaly}")
    end)
  else
    IO.puts("  No specific anomalies detected")
  end
end)

IO.puts("""

\n
╔═══════════════════════════════════════════════════════════════════════════╗
║                          DEMONSTRATION COMPLETE                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

Key Takeaways:
1. Text messages can be encoded into musical MIDI files
2. Multiple encoding layers increase information density
3. Statistical analysis can detect encoded patterns
4. Trade-off exists between capacity and detectability

This system demonstrates both encoding (offensive) and detection (defensive)
capabilities for educational and security research purposes.

DISCLAIMER: For authorized educational and research use only.

""")
