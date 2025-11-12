#!/usr/bin/env elixir

# Basic usage examples for TemporalEncoder

IO.puts("\n=== Temporal Encoder Examples ===\n")

# Example 1: Simple encoding
IO.puts("1. Encoding 'SOS' to timestamps:")
{:ok, timestamps} = TemporalEncoder.encode("SOS", format: :relative)
IO.inspect(timestamps, label: "Timestamps (ms)")

# Show the morse code
{:ok, morse} = TemporalEncoder.MorseEncoder.encode("SOS")
IO.puts("Morse code: #{morse}")

# Example 2: Decoding timestamps back
IO.puts("\n2. Decoding timestamps back to text:")
{:ok, decoded} = TemporalEncoder.decode(timestamps)
IO.puts("Decoded text: #{decoded}")

# Example 3: Message information
IO.puts("\n3. Getting message information:")
{:ok, info} = TemporalEncoder.info("HELLO")
IO.puts("Message: HELLO")
IO.puts("Character count: #{info.character_count}")
IO.puts("Signal count: #{info.signal_count}")
IO.puts("Duration: #{info.duration_ms}ms (#{info.duration_ms / 1000}s)")
IO.puts("Morse code: #{info.morse_code}")

# Example 4: Different timing speeds
IO.puts("\n4. Same message with different speeds:")
message = "HI"

Enum.each([50, 100, 200, 500], fn base_unit ->
  {:ok, info} = TemporalEncoder.info(message, base_unit_ms: base_unit)
  IO.puts("  #{base_unit}ms/unit: #{info.duration_ms}ms total, #{info.signal_count} signals")
end)

# Example 5: Scheduling with callback
IO.puts("\n5. Scheduling signals with callback:")
IO.puts("Encoding and scheduling 'TEST'...")

{:ok, result} = TemporalEncoder.schedule(
  "TEST",
  base_unit_ms: 50,  # Fast for demo
  callback: fn %{offset_ms: offset, scheduled_time: time} ->
    IO.puts("  ⚡ Signal at #{offset}ms (#{DateTime.to_string(time)})")
  end
)

IO.puts("Scheduled #{result.scheduled} signals")
IO.puts("Started at: #{DateTime.to_string(result.start_time)}")
IO.puts("Will end at: #{DateTime.to_string(result.end_time)}")

# Wait for completion
Process.sleep(result.end_time |> DateTime.diff(result.start_time, :millisecond) |> Kernel.+(500))

# Example 6: Timing analysis
IO.puts("\n6. Analyzing timestamp intervals:")
{:ok, timestamps} = TemporalEncoder.encode("OK", format: :relative)
analysis = TemporalEncoder.Decoder.analyze_timing(timestamps)
IO.puts("Detected base unit: #{analysis.detected_base_unit_ms}ms")
IO.puts("Intervals (in units): #{inspect(analysis.intervals_in_units)}")

# Example 7: Character support
IO.puts("\n7. Supported characters:")
test_string = "HELLO WORLD 123"
{:ok, morse} = TemporalEncoder.MorseEncoder.encode(test_string)
IO.puts("Text: #{test_string}")
IO.puts("Morse: #{morse}")

{:ok, decoded} = TemporalEncoder.MorseEncoder.decode(morse)
IO.puts("Decoded: #{decoded}")
IO.puts("Match: #{test_string == decoded}")

IO.puts("\n=== Examples Complete ===\n")
