#!/usr/bin/env elixir

# Music Encoding Demonstration
#
# This demo showcases how benign messages can be encoded into musical structures
# using multiple steganographic techniques. It also demonstrates detection methods
# for security research purposes.

IO.puts("""

╔═══════════════════════════════════════════════════════════════════════╗
║                   MUSIC STEGANOGRAPHY DEMONSTRATION                   ║
║                   Educational & Research Purposes Only                ║
╚═══════════════════════════════════════════════════════════════════════╝

This demonstration shows how information can be hidden in musical patterns
using pitch sequences, rhythmic patterns, and melodic intervals.

""")

alias TemporalEncoder.MusicEncoder
alias TemporalEncoder.MusicDecoder
alias TemporalEncoder.MusicAnalyzer

# ============================================================================
# SECTION 1: Basic Pitch Encoding
# ============================================================================

IO.puts("""
═══════════════════════════════════════════════════════════════════════════
SECTION 1: Basic Pitch Encoding
═══════════════════════════════════════════════════════════════════════════

Encoding Method: Characters mapped directly to musical pitches
Message: "HELLO WORLD"

""")

message1 = "HELLO WORLD"
IO.puts("Original message: \"#{message1}\"")

{:ok, midi_pitch} = MusicEncoder.encode(message1, encoding_mode: :pitch, add_harmony: false)

IO.puts("✓ Encoded to MIDI (#{byte_size(midi_pitch)} bytes)")

{:ok, info1} = MusicEncoder.encoding_info(message1, encoding_mode: :pitch)

IO.puts("""
Encoding Statistics:
  - Characters: #{info1.character_count}
  - Notes generated: #{info1.note_count}
  - Duration: #{Float.round(info1.duration_beats, 2)} beats
  - Pitch range: #{info1.pitch_range.lowest} to #{info1.pitch_range.highest} (#{info1.pitch_range.span_semitones} semitones)
""")

{:ok, decoded1} = MusicDecoder.decode(midi_pitch, encoding_mode: :pitch)
IO.puts("✓ Decoded message: \"#{decoded1}\"")
IO.puts("✓ Encoding/Decoding: #{if decoded1 == message1, do: "SUCCESS", else: "FAILED"}")

# ============================================================================
# SECTION 2: Rhythm Encoding
# ============================================================================

IO.puts("""

═══════════════════════════════════════════════════════════════════════════
SECTION 2: Rhythm Encoding
═══════════════════════════════════════════════════════════════════════════

Encoding Method: Binary representation of ASCII encoded in note durations
Message: "SOS"

This method uses note duration patterns to encode binary data:
  - Short notes (0.25 beats) = 0 bit
  - Long notes (0.5 beats) = 1 bit

Each character requires 8 notes (8 bits).

""")

message2 = "SOS"
IO.puts("Original message: \"#{message2}\"")

# Show binary representation
IO.puts("\nBinary representation:")

String.graphemes(message2)
|> Enum.each(fn char ->
  ascii = :binary.first(char)
  binary = Integer.to_string(ascii, 2) |> String.pad_leading(8, "0")
  IO.puts("  '#{char}' (ASCII #{ascii}): #{binary}")
end)

{:ok, midi_rhythm} = MusicEncoder.encode(message2, encoding_mode: :rhythm, add_harmony: false)

IO.puts("\n✓ Encoded to MIDI (#{byte_size(midi_rhythm)} bytes)")

{:ok, info2} = MusicEncoder.encoding_info(message2, encoding_mode: :rhythm)

IO.puts("""
Encoding Statistics:
  - Characters: #{info2.character_count}
  - Notes generated: #{info2.note_count} (#{info2.note_count / info2.character_count} notes per character)
  - Duration: #{Float.round(info2.duration_beats, 2)} beats
""")

{:ok, decoded2} = MusicDecoder.decode(midi_rhythm, encoding_mode: :rhythm)
IO.puts("✓ Decoded message: \"#{decoded2}\"")
IO.puts("✓ Encoding/Decoding: #{if String.starts_with?(decoded2, message2), do: "SUCCESS", else: "PARTIAL"}")

# ============================================================================
# SECTION 3: Multi-Layer Encoding with Harmony
# ============================================================================

IO.puts("""

═══════════════════════════════════════════════════════════════════════════
SECTION 3: Multi-Layer Encoding with Harmony
═══════════════════════════════════════════════════════════════════════════

Encoding Method: Multiple encoding layers + harmonic backing for naturalness
Message: "MEET AT NOON"

This advanced method combines:
  1. Pitch encoding (primary)
  2. Duration encoding (secondary)
  3. Velocity encoding (tertiary)
  4. Harmonic chord progression (camouflage)

The harmony makes the music sound more natural and harder to detect.

""")

message3 = "MEET AT NOON"
IO.puts("Original message: \"#{message3}\"")

{:ok, midi_multi} =
  MusicEncoder.encode(message3,
    encoding_mode: :multi_layer,
    add_harmony: true,
    tempo: 120,
    key: :c_major
  )

IO.puts("✓ Encoded to MIDI (#{byte_size(midi_multi)} bytes)")

{:ok, info3} = MusicEncoder.encoding_info(message3, encoding_mode: :multi_layer)

IO.puts("""
Encoding Statistics:
  - Characters: #{info3.character_count}
  - Notes generated: #{info3.note_count}
  - Duration: #{Float.round(info3.duration_beats, 2)} beats (#{Float.round(info3.duration_beats / 2, 1)} seconds at 120 BPM)
  - Musical key: #{info3.musical_key}
""")

{:ok, decoded3} = MusicDecoder.decode(midi_multi, encoding_mode: :multi_layer)
IO.puts("✓ Decoded message: \"#{decoded3}\"")
IO.puts("✓ Encoding/Decoding: #{if decoded3 == message3, do: "SUCCESS", else: "FAILED"}")

# Save to file for playback
midi_filename = "/tmp/temporal_encoder_demo.mid"
File.write!(midi_filename, midi_multi)
IO.puts("\n✓ Saved to: #{midi_filename}")
IO.puts("  (You can open this file in any MIDI player or music software)")

# ============================================================================
# SECTION 4: Security Analysis & Detection
# ============================================================================

IO.puts("""

═══════════════════════════════════════════════════════════════════════════
SECTION 4: Security Analysis & Detection
═══════════════════════════════════════════════════════════════════════════

This section demonstrates forensic analysis techniques for detecting
steganographic content in music.

""")

IO.puts("Analyzing the multi-layer encoded file...")

{:ok, analysis} = MusicAnalyzer.analyze_file(midi_multi)

IO.puts("""
Detection Results:
  - Overall Suspicion Score: #{Float.round(analysis.overall_suspicion_score, 3)} / 1.0
  - Risk Level: #{analysis.risk_level |> Atom.to_string() |> String.upcase()}

  Detailed Scores:
    • Pitch Entropy: #{Float.round(analysis.suspicion_scores.pitch_entropy_score, 3)}
    • Rhythm Regularity: #{Float.round(analysis.suspicion_scores.rhythm_regularity_score, 3)}
    • Interval Patterns: #{Float.round(analysis.suspicion_scores.interval_unnaturalness_score, 3)}
    • Encoding Patterns: #{Float.round(analysis.suspicion_scores.encoding_pattern_score, 3)}
""")

if length(analysis.anomalies) > 0 do
  IO.puts("  Anomalies Detected:")

  Enum.each(analysis.anomalies, fn anomaly ->
    IO.puts("    - #{anomaly}")
  end)
else
  IO.puts("  No specific anomalies detected")
end

# ============================================================================
# SECTION 5: Comparison to Natural Music
# ============================================================================

IO.puts("""

═══════════════════════════════════════════════════════════════════════════
SECTION 5: Comparison to Natural Music Baseline
═══════════════════════════════════════════════════════════════════════════

Comparing encoded music against statistical baseline of natural music...

""")

{:ok, comparison} = MusicAnalyzer.compare_to_natural_music(midi_multi)

IO.puts("""
Deviation Analysis:
  - Pitch Distribution Deviation: #{Float.round(comparison.pitch_deviation, 3)}
  - Rhythm Pattern Deviation: #{Float.round(comparison.rhythm_deviation, 3)}
  - Interval Distribution Deviation: #{Float.round(comparison.interval_deviation, 3)}

  Overall Deviation: #{Float.round(comparison.overall_deviation, 3)}

  Interpretation: #{comparison.interpretation}
""")

# ============================================================================
# SECTION 6: Full Forensic Report
# ============================================================================

IO.puts("""

═══════════════════════════════════════════════════════════════════════════
SECTION 6: Full Forensic Report
═══════════════════════════════════════════════════════════════════════════
""")

report = MusicAnalyzer.generate_report(analysis)
IO.puts(report)

# ============================================================================
# SECTION 7: Additional Educational Examples
# ============================================================================

IO.puts("""
═══════════════════════════════════════════════════════════════════════════
SECTION 7: Additional Educational Examples
═══════════════════════════════════════════════════════════════════════════

Testing various benign message types:

""")

benign_messages = [
  {"WEATHER SUNNY", "Weather report"},
  {"MEETING 3PM", "Schedule notification"},
  {"STATUS OK", "System status"},
  {"HELLO ALICE", "Greeting message"},
  {"TEST 123", "Test message"}
]

Enum.each(benign_messages, fn {message, description} ->
  IO.puts("#{description}: \"#{message}\"")
  {:ok, midi} = MusicEncoder.encode(message, encoding_mode: :multi_layer, add_harmony: true)
  {:ok, decoded} = MusicDecoder.decode(midi, encoding_mode: :multi_layer)
  {:ok, analysis} = MusicAnalyzer.analyze_file(midi)

  status = if decoded == message, do: "✓", else: "✗"

  IO.puts(
    "  #{status} Encoded: #{byte_size(midi)} bytes | Decoded: \"#{decoded}\" | Suspicion: #{Float.round(analysis.overall_suspicion_score, 2)}"
  )

  IO.puts("")
end)

# ============================================================================
# Educational Summary
# ============================================================================

IO.puts("""

╔═══════════════════════════════════════════════════════════════════════════╗
║                          EDUCATIONAL SUMMARY                              ║
╚═══════════════════════════════════════════════════════════════════════════╝

KEY CONCEPTS DEMONSTRATED:

1. ENCODING METHODS
   • Pitch Encoding: Character-to-note mapping
   • Rhythm Encoding: Binary data in note durations
   • Multi-layer Encoding: Combined encoding dimensions
   • Harmonic Camouflage: Making encoded music sound natural

2. DETECTION TECHNIQUES
   • Statistical Analysis: Entropy, chi-square tests
   • Pattern Recognition: Binary patterns, regularity
   • Baseline Comparison: Deviation from natural music
   • Anomaly Detection: Multiple suspicious indicators

3. SECURITY RESEARCH APPLICATIONS
   • Forensic analysis of suspicious audio files
   • Developing detection algorithms
   • Understanding information hiding techniques
   • Creating countermeasures and defenses

4. LIMITATIONS & DETECTABILITY
   • All encoding methods leave statistical traces
   • Perfect naturalness is impossible with high information density
   • Multiple detection methods increase discovery probability
   • Trade-off between capacity and stealth

EDUCATIONAL VALUE:
This demonstration shows both offensive (encoding) and defensive (detection)
aspects of music steganography, helping security researchers understand:
  - How covert channels work in practice
  - What patterns indicate hidden information
  - How to design effective detection systems
  - The limits of steganographic techniques

═══════════════════════════════════════════════════════════════════════════

DISCLAIMER: This tool is for educational and authorized security research
only. Always obtain proper authorization before testing.

═══════════════════════════════════════════════════════════════════════════
""")
