defmodule TemporalEncoder.MorseEncoder do
  @moduledoc """
  Converts text to morse code representation.

  Uses International Morse Code standard with dots (.) and dashes (-).
  """

  @morse_code %{
    "A" => ".-",
    "B" => "-...",
    "C" => "-.-.",
    "D" => "-..",
    "E" => ".",
    "F" => "..-.",
    "G" => "--.",
    "H" => "....",
    "I" => "..",
    "J" => ".---",
    "K" => "-.-",
    "L" => ".-..",
    "M" => "--",
    "N" => "-.",
    "O" => "---",
    "P" => ".--.",
    "Q" => "--.-",
    "R" => ".-.",
    "S" => "...",
    "T" => "-",
    "U" => "..-",
    "V" => "...-",
    "W" => ".--",
    "X" => "-..-",
    "Y" => "-.--",
    "Z" => "--..",
    "0" => "-----",
    "1" => ".----",
    "2" => "..---",
    "3" => "...--",
    "4" => "....-",
    "5" => ".....",
    "6" => "-....",
    "7" => "--...",
    "8" => "---..",
    "9" => "----.",
    "." => ".-.-.-",
    "," => "--..--",
    "?" => "..--..",
    "'" => ".----.",
    "!" => "-.-.--",
    "/" => "-..-.",
    "(" => "-.--.",
    ")" => "-.--.-",
    "&" => ".-...",
    ":" => "---...",
    ";" => "-.-.-.",
    "=" => "-...-",
    "+" => ".-.-.",
    "-" => "-....-",
    "_" => "..--.-",
    "\"" => ".-..-.",
    "$" => "...-..-",
    "@" => ".--.-."
  }

  @doc """
  Encodes text to morse code as array of letter patterns and word markers.

  Returns a list where each element is either a morse pattern or "/" for word boundary.

  ## Examples

      iex> TemporalEncoder.MorseEncoder.encode("SOS")
      {:ok, ["...", "---", "..."]}

      iex> TemporalEncoder.MorseEncoder.encode("HI MOM")
      {:ok, ["....", "..", "/", "--", "---", "--"]}
  """
  def encode(text) when is_binary(text) do
    text
    |> String.upcase()
    |> String.graphemes()
    |> encode_characters([])
  end

  defp encode_characters([], acc), do: {:ok, Enum.reverse(acc)}

  defp encode_characters([" " | rest], acc) do
    # Word space marker
    encode_characters(rest, ["/" | acc])
  end

  defp encode_characters([char | rest], acc) do
    case Map.get(@morse_code, char) do
      nil ->
        {:error, "Unsupported character: #{char}"}

      morse ->
        encode_characters(rest, [morse | acc])
    end
  end

  @doc """
  Returns the morse code mapping.
  """
  def morse_code_map, do: @morse_code

  @doc """
  Decodes morse code back to text.

  Expects a list of morse patterns with '/' for word boundaries.

  ## Examples

      iex> TemporalEncoder.MorseEncoder.decode(["...", "---", "..."])
      {:ok, "SOS"}

      iex> TemporalEncoder.MorseEncoder.decode(["....", "..", "/", "--", "---", "--"])
      {:ok, "HI MOM"}
  """
  def decode(morse_patterns) when is_list(morse_patterns) do
    # Build reverse mapping
    reverse_map = Enum.into(@morse_code, %{}, fn {k, v} -> {v, k} end)

    # Decode each pattern
    morse_patterns
    |> Enum.map(fn pattern ->
      case pattern do
        "/" -> " "
        morse_letter -> Map.get(reverse_map, morse_letter)
      end
    end)
    |> Enum.reduce({:ok, []}, fn
      nil, _ -> {:error, "Unknown morse code"}
      char, {:ok, acc} -> {:ok, [char | acc]}
      _, {:error, _} = err -> err
    end)
    |> case do
      {:ok, chars} -> {:ok, chars |> Enum.reverse() |> Enum.join()}
      error -> error
    end
  end

  defp collect_results(results) do
    Enum.reduce_while(results, {:ok, []}, fn
      {:ok, val}, {:ok, acc} -> {:cont, {:ok, [val | acc]}}
      {:error, _} = error, _acc -> {:halt, error}
    end)
    |> case do
      {:ok, values} -> {:ok, values |> Enum.reverse() |> Enum.join()}
      error -> error
    end
  end
end
