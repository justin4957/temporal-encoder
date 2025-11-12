# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Temporal Encoder is an Elixir-based demonstration project that encodes text messages into precisely-timed events. Information is carried entirely in the temporal spacing between signals rather than in signal content itself. The system uses morse code timing standards to create a covert communication channel where the timing of events (API calls, network packets, etc.) carries the encoded message.

## Core Architecture

The project contains two main encoding systems:

### 1. Temporal Encoding (Timing-Based)

Pipeline architecture with five main components:

```
Text → MorseEncoder → TimestampGenerator → Scheduler → Decoder → Text
```

**Key Modules:**
- **`TemporalEncoder`** (lib/temporal_encoder.ex): Main API module providing high-level encode/decode/schedule functions
- **`TemporalEncoder.MorseEncoder`** (lib/temporal_encoder/morse_encoder.ex): Converts text to/from morse code patterns (dots, dashes, boundaries)
- **`TemporalEncoder.TimestampGenerator`** (lib/temporal_encoder/timestamp_generator.ex): Generates precise timestamps from morse patterns using interval-based encoding
- **`TemporalEncoder.Decoder`** (lib/temporal_encoder/decoder.ex): Reconstructs text from timestamps by analyzing intervals with auto-detection and tolerance handling
- **`TemporalEncoder.Scheduler`** (lib/temporal_encoder/scheduler.ex): Executes callbacks or HTTP requests at precise timestamps using concurrent Task processes

### 2. Music Encoding (MIDI-Based)

Multi-layer steganographic system:

```
Text → MusicEncoder → MIDI Data → MusicDecoder → Text
                ↓
         MusicAnalyzer (Detection)
```

**Key Modules:**
- **`TemporalEncoder.MusicEncoder`** (lib/temporal_encoder/music_encoder.ex): Encodes text into MIDI using pitch, rhythm, interval, and harmonic layers
- **`TemporalEncoder.MusicEncoder.PitchMapper`**: Maps characters to musical pitches with scale awareness
- **`TemporalEncoder.MusicEncoder.RhythmEncoder`**: Encodes binary data in note durations and analyzes rhythmic patterns
- **`TemporalEncoder.MusicEncoder.MIDIGenerator`**: Generates and parses standard MIDI format files
- **`TemporalEncoder.MusicDecoder`** (lib/temporal_encoder/music_decoder.ex): Extracts text from MIDI by analyzing multiple encoding layers
- **`TemporalEncoder.MusicAnalyzer`** (lib/temporal_encoder/music_analyzer.ex): Forensic analysis and detection tools for identifying steganographic content

### Temporal Encoding Scheme

The temporal system uses **interval-based encoding** where each interval between timestamps encodes information about the **previous** timestamp:

- **2 units** (200ms default): dit (.)
- **3 units**: letter boundary
- **4 units**: dah (-)
- **5 units**: dit + letter boundary
- **6 units**: word boundary
- **7 units**: dah + letter boundary
- **8 units**: dit + word boundary
- **10 units**: dah + word boundary

The final timestamp in a sequence marks where the last signal ends, allowing the decoder to calculate the duration and type of the final signal.

### Music Encoding Scheme

The music system uses **multi-layer encoding** across four dimensions:

1. **Pitch Layer**: Characters mapped to MIDI note numbers (A-Z → C major scale, 0-9 → C6 octave, punctuation → chromatic)
2. **Rhythm Layer**: Note durations encode binary data (short = 0 bit, long = 1 bit)
3. **Interval Layer**: Melodic intervals between notes carry information based on ASCII values
4. **Harmony Layer**: Chord progressions (I-IV-V-I) provide naturalness and additional encoding capacity

**Encoding Modes:**
- `:pitch` - Simple character-to-pitch mapping
- `:rhythm` - Binary data in note durations (8 notes per character)
- `:interval` - Information in melodic leaps
- `:multi_layer` - All methods combined for maximum density

### Data Flow

**Temporal:**
1. **Encoding**: Text → List of morse patterns (e.g., `["...", "---", "..."]`) → List of timestamps with intervals encoding signal types
2. **Decoding**: Timestamps → Calculate intervals → Decode intervals to morse → Convert morse to text
3. **Scheduling**: Timestamps → Spawn concurrent Task processes → Sleep until scheduled time → Execute callback/HTTP request

**Music:**
1. **Encoding**: Text → Note sequence (pitch/duration/velocity) → MIDI events → MIDI binary file
2. **Decoding**: MIDI binary → Parse events → Extract notes → Analyze patterns → Decode to text
3. **Analysis**: MIDI binary → Statistical analysis → Suspicion scoring → Forensic report

## Development Commands

### Dependencies and Compilation

```bash
# Install dependencies
mix deps.get

# Compile the project
mix compile

# Format code (REQUIRED before commits/PRs)
mix format

# Verify code is properly formatted
mix format --check-formatted
```

### Testing

```bash
# Run all tests
mix test

# Run a specific test file
mix test test/morse_encoder_test.exs

# Run a specific test by line number
mix test test/temporal_encoder_test.exs:42

# Run tests with detailed output
mix test --trace
```

### Running Examples

The project includes demonstration scripts in `examples/`:

```bash
# Basic encoding/decoding demonstration
mix run examples/basic_usage.exs

# API timing covert channel demo
mix run examples/api_timing_demo.exs

# Steganographic encoding (hides messages in plausible data formats)
mix run examples/steganographic_encoding_demo.exs

# Network covert channel demonstrations (DNS, HTTP, TCP, etc.)
mix run examples/network_covert_channel_demo.exs

# Music encoding with forensic analysis (encodes text into MIDI)
mix run examples/music_encoding_demo.exs
```

### Documentation

```bash
# Generate HTML documentation
mix docs

# Documentation will be in doc/index.html
```

## Important Implementation Details

### Timestamp Generation Logic

The timestamp generator walks through morse patterns sequentially:
- For each dit (.), emit timestamp at current time, advance 2 units
- For each dah (-), emit timestamp at current time, advance 4 units
- After each letter (except before word boundaries), add 3-unit gap
- For word boundaries (/), advance 6 units without emitting timestamp
- Always emit a final timestamp to mark the end of the last signal

### Decoder Interval Analysis

The decoder processes timestamps by:
1. Calculating intervals between consecutive timestamps
2. Normalizing intervals to unit multiples based on detected/provided base unit
3. Decoding each interval to determine what the **previous** timestamp was
4. Grouping decoded symbols by boundaries into letters, then converting to text

### Timing Precision and Tolerance

- Default base unit: 200ms
- Default tolerance: 30% (configurable)
- Auto-detection uses minimum interval approach with validation
- Scheduler uses Elixir processes and `Process.sleep/1` for timing (not suitable for sub-millisecond precision)

### Music Encoding Implementation Details

**MIDI Generation:**
- Pure Elixir implementation (no external dependencies beyond basic hex packages)
- Generates standard MIDI Format 1 files (multi-track, synchronous)
- Uses 480 ticks per beat for timing resolution
- Supports multiple tracks (melody + harmony)

**Encoding Strategy:**
- Pitch encoding uses scale-aware mapping to create musically plausible sequences
- Rhythm encoding converts ASCII to 8-bit binary, then maps bits to note durations
- Interval encoding uses ASCII values to determine melodic intervals (modulo 12)
- Multi-layer combines all approaches with velocity as additional dimension

**Detection Methodology:**
- Statistical analysis: entropy, chi-square tests, distribution comparisons
- Pattern recognition: binary alternation, perfect periodicity, bit-like durations
- Baseline comparison: deviation from natural Western music statistics
- Multiple indicators combined for overall suspicion score (0.0-1.0)

**Key Detection Signatures:**
- Pitch entropy outside 1.5-3.0 bits range
- Only 1-2 unique note durations (suggests binary encoding)
- Perfect alternation between two values
- Uniform entropy across all sections
- Intervals in exact 1:2 ratio

## Testing Considerations

**Temporal System:**
- Tests use `format: :relative` for predictable timestamp values
- Decoder tests verify round-trip encoding/decoding
- Auto-detection tests validate unit detection with timing jitter
- Scheduler tests use callbacks rather than actual HTTP requests

**Music System:**
- MIDI generation tests verify proper binary format
- Encoding/decoding tests use benign messages only
- Detection tests validate suspicion scoring accuracy
- Analysis tests check statistical calculations

## Security and Ethics Context

This is a **demonstration and educational project** for:
- Understanding covert communication channels
- Teaching information theory and encoding concepts
- Security research and detection algorithm development
- Exploring timing-based and music-based side channels
- Developing forensic analysis tools for steganography detection

**Important**: Always obtain proper authorization before testing on any network. Use only in controlled environments for defensive security, CTF challenges, or authorized security research. The music encoding system is provided for educational purposes to help security researchers understand both offensive (encoding) and defensive (detection) aspects of audio steganography.

## CI/PR Workflow

Before creating a pull request:
1. Run `mix format` to ensure code is properly formatted
2. Verify formatting with `mix format --check-formatted`
3. Run `mix test` to ensure all tests pass
4. After PR creation, verify all GitHub CI checks pass using `gh pr checks <pr-number>`
   - Expected checks: "Code Quality", "Test", "Build Escript"
5. Fix any CI failures before considering the task complete
