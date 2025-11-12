defmodule TemporalEncoder.MorseEncoderTest do
  use ExUnit.Case
  alias TemporalEncoder.MorseEncoder

  describe "encode/1" do
    test "encodes simple letters" do
      assert {:ok, "..."} = MorseEncoder.encode("S")
      assert {:ok, "---"} = MorseEncoder.encode("O")
      assert {:ok, ".-"} = MorseEncoder.encode("A")
    end

    test "encodes words" do
      {:ok, morse} = MorseEncoder.encode("SOS")
      assert morse == "... --- ..."
    end

    test "encodes sentences with spaces" do
      {:ok, morse} = MorseEncoder.encode("HI MOM")
      assert String.contains?(morse, "/")
    end

    test "handles lowercase" do
      {:ok, lower} = MorseEncoder.encode("hello")
      {:ok, upper} = MorseEncoder.encode("HELLO")
      assert lower == upper
    end

    test "encodes numbers" do
      {:ok, morse} = MorseEncoder.encode("123")
      assert is_binary(morse)
      assert String.length(morse) > 0
    end

    test "encodes punctuation" do
      {:ok, morse} = MorseEncoder.encode("HELLO.")
      assert is_binary(morse)
    end

    test "returns error for unsupported characters" do
      assert {:error, _} = MorseEncoder.encode("Hello\n")
    end
  end

  describe "decode/1" do
    test "decodes simple morse code" do
      assert {:ok, "SOS"} = MorseEncoder.decode("... --- ...")
      assert {:ok, "A"} = MorseEncoder.decode(".-")
      assert {:ok, "E"} = MorseEncoder.decode(".")
    end

    test "decodes words" do
      {:ok, text} = MorseEncoder.decode(".... . .-.. .-.. ---")
      assert text == "HELLO"
    end

    test "decodes sentences" do
      {:ok, text} = MorseEncoder.decode(".... .. / -- --- --")
      assert text == "HI MOM"
    end

    test "returns error for invalid morse code" do
      assert {:error, _} = MorseEncoder.decode("......")
    end
  end

  describe "round-trip encoding" do
    test "preserves text through encode/decode" do
      texts = ["SOS", "HELLO", "WORLD", "123", "TEST"]

      Enum.each(texts, fn text ->
        {:ok, morse} = MorseEncoder.encode(text)
        {:ok, decoded} = MorseEncoder.decode(morse)
        assert decoded == text
      end)
    end

    test "handles spaces correctly" do
      text = "HELLO WORLD"
      {:ok, morse} = MorseEncoder.encode(text)
      {:ok, decoded} = MorseEncoder.decode(morse)
      assert decoded == text
    end
  end

  describe "morse_code_map/0" do
    test "returns complete mapping" do
      map = MorseEncoder.morse_code_map()
      assert is_map(map)
      assert Map.has_key?(map, "A")
      assert Map.has_key?(map, "Z")
      assert Map.has_key?(map, "0")
      assert Map.has_key?(map, "9")
    end
  end
end
