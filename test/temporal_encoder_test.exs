defmodule TemporalEncoderTest do
  use ExUnit.Case
  doctest TemporalEncoder

  describe "encode/2" do
    test "encodes text to relative timestamps" do
      {:ok, timestamps} = TemporalEncoder.encode("SOS", format: :relative)

      assert is_list(timestamps)
      assert length(timestamps) == 10
      assert List.first(timestamps) == 0
    end

    test "encodes text to absolute timestamps" do
      start_time = DateTime.utc_now()

      {:ok, timestamps} =
        TemporalEncoder.encode("A",
          format: :absolute,
          start_time: start_time
        )

      assert is_list(timestamps)
      assert Enum.all?(timestamps, &match?(%DateTime{}, &1))
      assert List.first(timestamps) == start_time
    end

    test "respects custom base unit" do
      {:ok, fast} = TemporalEncoder.encode("A", format: :relative, base_unit_ms: 100)
      {:ok, slow} = TemporalEncoder.encode("A", format: :relative, base_unit_ms: 200)

      assert List.last(fast) < List.last(slow)
    end
  end

  describe "decode/2" do
    test "decodes relative timestamps back to text" do
      message = "HELLO"
      {:ok, timestamps} = TemporalEncoder.encode(message, format: :relative)
      {:ok, decoded} = TemporalEncoder.decode(timestamps)

      assert decoded == message
    end

    test "decodes with auto-detection" do
      message = "TEST"

      {:ok, timestamps} =
        TemporalEncoder.encode(message,
          format: :relative,
          base_unit_ms: 150
        )

      {:ok, decoded} = TemporalEncoder.decode(timestamps, auto_detect_unit: true)
      assert decoded == message
    end

    test "handles absolute DateTime timestamps" do
      message = "SOS"
      start_time = DateTime.utc_now()

      {:ok, timestamps} =
        TemporalEncoder.encode(message,
          format: :absolute,
          start_time: start_time
        )

      {:ok, decoded} = TemporalEncoder.decode(timestamps)
      assert decoded == message
    end
  end

  describe "info/2" do
    test "returns message information" do
      {:ok, info} = TemporalEncoder.info("HELLO")

      assert info.character_count == 5
      assert info.signal_count > 0
      assert info.duration_ms > 0
      assert is_binary(info.morse_code)
    end

    test "calculates correct signal count" do
      {:ok, info} = TemporalEncoder.info("SOS")

      # S=3 signals, O=3 signals, S=3 signals + 1 end marker = 10 total
      assert info.signal_count == 10
    end
  end

  describe "schedule/2" do
    test "schedules with callback" do
      test_pid = self()

      {:ok, result} =
        TemporalEncoder.schedule(
          "HI",
          base_unit_ms: 10,
          callback: fn _data ->
            send(test_pid, :signal_received)
          end
        )

      assert result.scheduled > 0

      # Wait for at least one signal
      assert_receive :signal_received, 1000
    end

    test "returns scheduling information" do
      {:ok, result} =
        TemporalEncoder.schedule(
          "A",
          callback: fn _ -> :ok end
        )

      assert is_integer(result.scheduled)
      assert %DateTime{} = result.start_time
      assert %DateTime{} = result.end_time
      assert DateTime.compare(result.end_time, result.start_time) == :gt
    end
  end

  describe "round-trip encoding" do
    test "preserves message through encode/decode cycle" do
      messages = ["SOS", "HELLO", "TEST 123", "OK"]

      Enum.each(messages, fn message ->
        {:ok, timestamps} = TemporalEncoder.encode(message, format: :relative)
        {:ok, decoded} = TemporalEncoder.decode(timestamps)

        assert decoded == message
      end)
    end

    test "works with different base units" do
      message = "HI"
      base_units = [50, 100, 200, 500]

      Enum.each(base_units, fn base_unit ->
        {:ok, timestamps} =
          TemporalEncoder.encode(message,
            format: :relative,
            base_unit_ms: base_unit
          )

        {:ok, decoded} =
          TemporalEncoder.decode(timestamps,
            base_unit_ms: base_unit,
            auto_detect_unit: false
          )

        assert decoded == message
      end)
    end
  end
end
