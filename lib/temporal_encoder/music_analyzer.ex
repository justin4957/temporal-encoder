defmodule TemporalEncoder.MusicAnalyzer do
  @moduledoc """
  Security research tools for detecting and analyzing music-based steganography.

  This module provides forensic analysis capabilities for identifying potential
  covert channels in musical data. It implements various statistical tests and
  anomaly detection methods used in steganography research.

  ## Detection Methods

  ### Statistical Analysis
  - **Entropy analysis**: Measures information content in pitch/rhythm
  - **Chi-square test**: Detects non-random distributions
  - **Autocorrelation**: Identifies artificial patterns

  ### Musical Analysis
  - **Scale conformance**: Natural music follows key signatures
  - **Rhythmic naturalness**: Human music has characteristic patterns
  - **Harmonic progression**: Detects unusual chord sequences

  ### Behavioral Analysis
  - **Interval distribution**: Unnatural melodic leaps
  - **Duration patterns**: Suspiciously regular timing
  - **Velocity patterns**: Uniform dynamics suggest encoding

  ## Example Usage

      iex> {:ok, analysis} = MusicAnalyzer.analyze_file(midi_binary)
      iex> analysis.suspicion_score
      0.75  # 0.0 = natural, 1.0 = highly suspicious

      iex> MusicAnalyzer.generate_report(analysis)
      "Analysis Report:\\nSuspicion Score: 0.75 (High)\\n..."
  """

  alias TemporalEncoder.MusicDecoder
  alias TemporalEncoder.MusicEncoder.{PitchMapper, RhythmEncoder}

  @doc """
  Performs comprehensive analysis of MIDI data for steganographic content.

  Returns a detailed report including multiple detection scores and indicators.
  """
  def analyze_file(midi_binary, options \\ []) when is_binary(midi_binary) do
    with {:ok, analysis} <- MusicDecoder.analyze(midi_binary, options) do
      suspicion_scores = calculate_suspicion_scores(analysis)
      anomaly_report = generate_anomaly_report(analysis, suspicion_scores)

      overall_suspicion = calculate_overall_suspicion(suspicion_scores)

      {:ok,
       %{
         overall_suspicion_score: overall_suspicion,
         risk_level: classify_risk_level(overall_suspicion),
         analysis: analysis,
         suspicion_scores: suspicion_scores,
         anomalies: anomaly_report,
         recommendations: generate_recommendations(overall_suspicion, anomaly_report)
       }}
    end
  end

  @doc """
  Compares a MIDI file against a corpus of known natural music.

  Uses statistical distance metrics to determine how much the file
  deviates from typical musical patterns.
  """
  def compare_to_natural_music(midi_binary, options \\ []) do
    natural_music_stats = get_natural_music_baseline()

    with {:ok, analysis} <- MusicDecoder.analyze(midi_binary, options) do
      pitch_distance =
        calculate_distribution_distance(
          analysis.pitch_analysis.pitch_class_distribution,
          natural_music_stats.pitch_distribution
        )

      rhythm_distance =
        calculate_entropy_distance(
          analysis.rhythm_analysis.rhythm_entropy,
          natural_music_stats.rhythm_entropy
        )

      interval_distance =
        calculate_distribution_distance(
          analysis.interval_analysis.interval_distribution,
          natural_music_stats.interval_distribution
        )

      {:ok,
       %{
         pitch_deviation: pitch_distance,
         rhythm_deviation: rhythm_distance,
         interval_deviation: interval_distance,
         overall_deviation: (pitch_distance + rhythm_distance + interval_distance) / 3,
         interpretation:
           interpret_deviation((pitch_distance + rhythm_distance + interval_distance) / 3)
       }}
    end
  end

  @doc """
  Performs chi-square test on pitch distribution.

  Tests whether the pitch distribution differs significantly from expected
  natural music distribution.
  """
  def chi_square_test(pitch_distribution) do
    expected_distribution = get_expected_pitch_distribution()
    total_notes = Enum.sum(Map.values(pitch_distribution))

    chi_square_sum =
      Enum.reduce(expected_distribution, 0, fn {pitch_class, expected_freq}, acc ->
        observed = Map.get(pitch_distribution, pitch_class, 0)
        expected = expected_freq * total_notes

        if expected > 0 do
          acc + :math.pow(observed - expected, 2) / expected
        else
          acc
        end
      end)

    # Degrees of freedom = number of categories - 1
    degrees_of_freedom = map_size(expected_distribution) - 1

    # Calculate p-value (simplified approximation)
    p_value = chi_square_p_value(chi_square_sum, degrees_of_freedom)

    %{
      chi_square: chi_square_sum,
      degrees_of_freedom: degrees_of_freedom,
      p_value: p_value,
      significant: p_value < 0.05,
      interpretation:
        if(p_value < 0.05,
          do: "Distribution significantly differs from natural music",
          else: "Distribution appears natural"
        )
    }
  end

  @doc """
  Detects patterns that suggest binary data encoding.

  Looks for characteristics typical of encoded binary data:
  - Perfectly alternating patterns
  - Regular periodicity
  - High entropy uniformity
  """
  def detect_binary_encoding_patterns(notes) do
    indicators = %{
      perfect_alternation: detect_perfect_alternation(notes),
      regular_periodicity: detect_regular_periodicity(notes),
      entropy_uniformity: detect_entropy_uniformity(notes),
      bit_like_durations: detect_bit_like_durations(notes)
    }

    suspicion_count = Enum.count(indicators, fn {_key, value} -> value end)

    %{
      indicators: indicators,
      pattern_count: suspicion_count,
      suspicion_score: suspicion_count / map_size(indicators),
      verdict:
        cond do
          suspicion_count >= 3 -> :highly_suspicious
          suspicion_count == 2 -> :suspicious
          suspicion_count == 1 -> :possibly_suspicious
          true -> :appears_natural
        end
    }
  end

  @doc """
  Generates a human-readable analysis report.

  Formats the analysis results into a comprehensive text report suitable
  for security researchers.
  """
  def generate_report(analysis_result) do
    """
    ═══════════════════════════════════════════════════════════════
    MUSIC STEGANOGRAPHY ANALYSIS REPORT
    ═══════════════════════════════════════════════════════════════

    OVERALL ASSESSMENT
    ──────────────────────────────────────────────────────────────
    Suspicion Score: #{Float.round(analysis_result.overall_suspicion_score, 3)} / 1.0
    Risk Level: #{format_risk_level(analysis_result.risk_level)}

    DETECTION SCORES
    ──────────────────────────────────────────────────────────────
    #{format_suspicion_scores(analysis_result.suspicion_scores)}

    ANOMALIES DETECTED
    ──────────────────────────────────────────────────────────────
    #{format_anomalies(analysis_result.anomalies)}

    STATISTICAL ANALYSIS
    ──────────────────────────────────────────────────────────────
    Note Count: #{analysis_result.analysis.note_count}
    Duration: #{Float.round(analysis_result.analysis.duration_beats, 2)} beats
    Pitch Entropy: #{Float.round(analysis_result.analysis.pitch_analysis.entropy, 3)} bits
    Rhythm Entropy: #{Float.round(analysis_result.analysis.rhythm_analysis.rhythm_entropy, 3)} bits

    RECOMMENDATIONS
    ──────────────────────────────────────────────────────────────
    #{format_recommendations(analysis_result.recommendations)}

    ═══════════════════════════════════════════════════════════════
    Report generated: #{DateTime.utc_now() |> DateTime.to_string()}
    ═══════════════════════════════════════════════════════════════
    """
  end

  # Private analysis functions

  defp calculate_suspicion_scores(analysis) do
    %{
      pitch_entropy_score: score_pitch_entropy(analysis.pitch_analysis),
      rhythm_regularity_score: score_rhythm_regularity(analysis.rhythm_analysis),
      interval_unnaturalness_score: score_interval_patterns(analysis.interval_analysis),
      encoding_pattern_score: analysis.encoding_detection.rhythm_suspicion
    }
  end

  defp score_pitch_entropy(pitch_analysis) do
    entropy = pitch_analysis.entropy

    cond do
      # Too high entropy
      entropy > 3.5 -> 0.9
      # Too low entropy
      entropy < 1.0 -> 0.8
      entropy > 3.0 or entropy < 1.5 -> 0.5
      # Normal range (1.5-3.0)
      true -> 0.1
    end
  end

  defp score_rhythm_regularity(rhythm_analysis) do
    variety = rhythm_analysis.duration_variety
    total_durations = map_size(rhythm_analysis.duration_distribution)

    cond do
      # Only one duration - highly suspicious
      variety == 1 -> 0.95
      # Binary-like
      variety == 2 and total_durations >= 8 -> 0.85
      variety <= 2 -> 0.7
      # Too much variety
      variety >= 8 -> 0.6
      # Normal variety
      true -> 0.2
    end
  end

  defp score_interval_patterns(interval_analysis) do
    mean_interval = abs(interval_analysis.mean_interval)
    interval_variety = map_size(interval_analysis.interval_distribution)

    cond do
      # All same interval
      interval_variety == 1 -> 0.9
      # Large leaps
      mean_interval > 7 -> 0.7
      interval_variety <= 2 -> 0.6
      true -> 0.2
    end
  end

  defp calculate_overall_suspicion(scores) do
    score_values = Map.values(scores)
    Enum.sum(score_values) / length(score_values)
  end

  defp generate_anomaly_report(analysis, suspicion_scores) do
    anomalies = []

    anomalies =
      if suspicion_scores.pitch_entropy_score > 0.5 do
        ["Unusual pitch entropy detected" | anomalies]
      else
        anomalies
      end

    anomalies =
      if suspicion_scores.rhythm_regularity_score > 0.6 do
        ["Suspicious rhythm regularity" | anomalies]
      else
        anomalies
      end

    anomalies =
      if suspicion_scores.interval_unnaturalness_score > 0.6 do
        ["Unnatural melodic intervals" | anomalies]
      else
        anomalies
      end

    anomalies =
      if analysis.encoding_detection.anomaly_indicators.entropy_anomaly do
        ["Entropy anomaly in rhythm patterns" | anomalies]
      else
        anomalies
      end

    Enum.reverse(anomalies)
  end

  defp classify_risk_level(score) do
    cond do
      score >= 0.7 -> :high
      score >= 0.5 -> :medium
      score >= 0.3 -> :low
      true -> :minimal
    end
  end

  defp generate_recommendations(suspicion_score, anomalies) do
    base_recommendations = [
      "Save this file for further forensic analysis",
      "Compare against known legitimate music from same source"
    ]

    additional =
      cond do
        suspicion_score >= 0.7 ->
          [
            "URGENT: High probability of steganographic content",
            "Recommend immediate manual inspection",
            "Consider running specialized steganalysis tools",
            "Extract and analyze note sequences for patterns"
          ]

        suspicion_score >= 0.5 ->
          [
            "Moderate suspicion warrants further investigation",
            "Run additional statistical tests",
            "Attempt decoding with known algorithms"
          ]

        suspicion_score >= 0.3 ->
          [
            "Low suspicion but some anomalies present",
            "Monitor if part of larger dataset"
          ]

        true ->
          [
            "File appears to be natural music",
            "No immediate action required"
          ]
      end

    if length(anomalies) > 0 do
      base_recommendations ++ additional
    else
      ["No significant anomalies detected", "File appears to be legitimate music"]
    end
  end

  # Helper functions for statistical tests

  defp get_natural_music_baseline do
    # Based on statistical analysis of common Western music
    %{
      pitch_distribution: %{
        # C
        0 => 0.15,
        # D
        2 => 0.12,
        # E
        4 => 0.13,
        # F
        5 => 0.11,
        # G
        7 => 0.14,
        # A
        9 => 0.12,
        # B
        11 => 0.10,
        1 => 0.04,
        3 => 0.03,
        6 => 0.03,
        8 => 0.02,
        10 => 0.01
      },
      rhythm_entropy: 2.0,
      interval_distribution: %{
        # Repeated notes
        0 => 0.20,
        1 => 0.10,
        # Steps
        2 => 0.15,
        3 => 0.12,
        4 => 0.10,
        5 => 0.08,
        # Fifth
        7 => 0.10,
        # Octave
        12 => 0.05
      }
    }
  end

  defp calculate_distribution_distance(observed, expected) do
    # Kullback-Leibler divergence
    keys = (Map.keys(observed) ++ Map.keys(expected)) |> Enum.uniq()

    divergence =
      Enum.reduce(keys, 0, fn key, acc ->
        obs = Map.get(observed, key, 0.001)
        exp = Map.get(expected, key, 0.001)

        acc + obs * :math.log(obs / exp)
      end)

    min(abs(divergence), 1.0)
  end

  defp calculate_entropy_distance(observed_entropy, expected_entropy) do
    min(abs(observed_entropy - expected_entropy) / expected_entropy, 1.0)
  end

  defp interpret_deviation(deviation) do
    cond do
      deviation > 0.8 -> "Extremely atypical - highly suspicious"
      deviation > 0.6 -> "Significantly different from natural music"
      deviation > 0.4 -> "Moderately different - warrants inspection"
      deviation > 0.2 -> "Slightly unusual but possibly natural"
      true -> "Consistent with natural music patterns"
    end
  end

  defp get_expected_pitch_distribution do
    # C major scale distribution in typical Western music
    %{
      0 => 0.15,
      2 => 0.12,
      4 => 0.13,
      5 => 0.11,
      7 => 0.14,
      9 => 0.12,
      11 => 0.10,
      1 => 0.04,
      3 => 0.03,
      6 => 0.03,
      8 => 0.02,
      10 => 0.01
    }
  end

  defp chi_square_p_value(chi_square, df) do
    # Simplified p-value approximation using Wilson-Hilferty transformation
    # For accurate results, use a proper statistical library
    z = :math.pow(chi_square / df, 1 / 3) - (1 - 2 / (9 * df))
    z = z / :math.sqrt(2 / (9 * df))

    # Approximate p-value from z-score
    1 - standard_normal_cdf(z)
  end

  defp standard_normal_cdf(z) do
    # Approximation of standard normal CDF
    0.5 * (1 + erf(z / :math.sqrt(2)))
  end

  defp erf(x) do
    # Approximation of error function
    sign = if x >= 0, do: 1, else: -1
    x = abs(x)

    a1 = 0.254829592
    a2 = -0.284496736
    a3 = 1.421413741
    a4 = -1.453152027
    a5 = 1.061405429
    p = 0.3275911

    t = 1.0 / (1.0 + p * x)
    y = 1.0 - ((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t * :math.exp(-x * x)

    sign * y
  end

  # Pattern detection helpers

  defp detect_perfect_alternation(notes) do
    if length(notes) < 4, do: false

    durations = Enum.map(notes, & &1.duration)

    # Check if durations alternate perfectly between two values
    unique_durations = Enum.uniq(durations)

    if length(unique_durations) == 2 do
      [d1, d2] = unique_durations

      durations
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.all?(fn [a, b] -> (a == d1 and b == d2) or (a == d2 and b == d1) end)
    else
      false
    end
  end

  defp detect_regular_periodicity(notes) do
    if length(notes) < 8, do: false

    durations = Enum.map(notes, & &1.duration)

    # Check for repeating pattern
    Enum.any?(2..4, fn period ->
      durations
      |> Enum.chunk_every(period)
      |> Enum.take(4)
      |> then(fn chunks ->
        length(Enum.uniq(chunks)) == 1
      end)
    end)
  end

  defp detect_entropy_uniformity(notes) do
    if length(notes) < 16, do: false

    # Split into chunks and compare entropy
    chunk_size = div(length(notes), 4)

    entropies =
      notes
      |> Enum.chunk_every(chunk_size)
      |> Enum.map(fn chunk ->
        durations = Enum.map(chunk, & &1.duration)
        calculate_entropy(durations)
      end)

    # If all chunks have similar entropy, it suggests encoding
    max_entropy = Enum.max(entropies)
    min_entropy = Enum.min(entropies)

    max_entropy - min_entropy < 0.5
  end

  defp detect_bit_like_durations(notes) do
    durations = Enum.map(notes, & &1.duration)
    unique_durations = Enum.uniq(durations)

    # Binary encoding often uses exactly 2 durations in 1:2 ratio
    if length(unique_durations) == 2 do
      [d1, d2] = Enum.sort(unique_durations)
      ratio = d2 / d1
      # Check if ratio is close to 2:1
      abs(ratio - 2.0) < 0.3
    else
      false
    end
  end

  defp calculate_entropy(values) do
    frequencies = Enum.frequencies(values)
    total = length(values)

    frequencies
    |> Enum.reduce(0, fn {_val, count}, acc ->
      p = count / total
      acc - p * :math.log2(p)
    end)
  end

  # Formatting functions for report

  defp format_risk_level(:high), do: "HIGH ⚠️"
  defp format_risk_level(:medium), do: "MEDIUM ⚡"
  defp format_risk_level(:low), do: "LOW ⓘ"
  defp format_risk_level(:minimal), do: "MINIMAL ✓"

  defp format_suspicion_scores(scores) do
    scores
    |> Enum.map(fn {key, value} ->
      name = key |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
      "  #{name}: #{Float.round(value, 3)}"
    end)
    |> Enum.join("\n")
  end

  defp format_anomalies([]), do: "  None detected"

  defp format_anomalies(anomalies) do
    anomalies
    |> Enum.with_index(1)
    |> Enum.map(fn {anomaly, idx} -> "  #{idx}. #{anomaly}" end)
    |> Enum.join("\n")
  end

  defp format_recommendations(recommendations) do
    recommendations
    |> Enum.with_index(1)
    |> Enum.map(fn {rec, idx} -> "  #{idx}. #{rec}" end)
    |> Enum.join("\n")
  end
end
