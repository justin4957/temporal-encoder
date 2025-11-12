# Temporal Encoder

<img width="567" height="734" alt="Screenshot 2025-11-12 at 8 31 56 AM" src="https://github.com/user-attachments/assets/f31cb65b-be03-4514-b145-17d2710f8af8" />


A demonstration application exploring novel communication methods through temporal patterns. This project encodes text messages into precisely-timed events, where information is carried entirely in the temporal spacing between signals rather than in the signals themselves.

## Concept

<img width="1299" height="508" alt="Screenshot 2025-11-12 at 7 40 46 AM" src="https://github.com/user-attachments/assets/bba747d4-c245-4f7b-84a1-e9023a499941" />

<img width="1272" height="469" alt="Screenshot 2025-11-12 at 7 41 14 AM" src="https://github.com/user-attachments/assets/5921b8b0-ece2-4f40-aaea-75116481c59e" />

Traditional communication encodes information in the content of signals (bits, symbols, words). Temporal Encoder takes a different approach: **the timing between events carries the message**.

Think of it as a sophisticated evolution of morse code, where:
- Each timestamp represents a signal
- The interval between timestamps encodes what the previous signal was
- Special interval patterns mark boundaries between letters and words
- No data payload is needed - the timing IS the data

## How It Works

The system uses a simple interval-based encoding scheme:

**Basic Intervals:**
- **2 units** (200ms default): dit (.)
- **3 units** (300ms): letter boundary
- **4 units** (400ms): dah (-)
- **6 units** (600ms): word boundary

**Combined Intervals** (signal + boundary):
- **5 units**: dit + letter boundary
- **7 units**: dah + letter boundary
- **8 units**: dit + word boundary
- **10 units**: dah + word boundary

### Visual Example: "SOS"

```
Message: S O S
Morse:   ... --- ...

Timeline (100ms base unit):
0ms   200   400   900   1300  1700  2400  2600  2800  3300
|     |     |     |     |     |     |     |     |     |
S(.) S(.) S(.)  O(-) O(-) O(-)  S(.) S(.) S(.)  END
      ↑           ↑           ↑           ↑
     dit         dah         dit        final
   (2 units)  (4 units)   (2 units)   timestamp

Intervals:
 200ms  200ms  500ms  400ms  400ms  700ms  200ms  200ms  500ms
  ↓      ↓      ↓      ↓      ↓      ↓      ↓      ↓      ↓
  dit   dit   dit+   dah    dah   dah+   dit    dit   dit+
              gap                  gap                 gap
```

### Detailed Timing Breakdown: "HELLO"

```
H = ....  (4 dits)
E = .     (1 dit)
L = .-..  (dit, dah, dit, dit)
L = .-..  (dit, dah, dit, dit)
O = ---   (3 dahs)

Visual Timeline (100ms units):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

H:  |  |  |  |     (dits at 0, 200, 400, 600ms)
    └─┴─┴─┴─       + 300ms letter gap → 900ms

E:  |              (dit at 900ms)
    └─             + 300ms letter gap → 1200ms

L:  | ── | |       (dit at 1200, dah at 1400, dits at 1800, 2000ms)
    └┴──┴┴─        + 300ms letter gap → 2300ms

L:  | ── | |       (dit at 2300, dah at 2500, dits at 2900, 3100ms)
    └┴──┴┴─        + 300ms letter gap → 3400ms

O:  ── ── ──       (dahs at 3400, 3800, 4200ms)
    ──┴──┴──       + final timestamp at 4700ms

Total: 17 timestamps, 4700ms duration
```

## Advanced Demos

### 🎭 Steganographic Encoding

Hide messages in plausible-looking data formats where timing patterns are embedded in the structure:

#### Base64 Structure Encoding
```
Message: "HIDE"

Encoded as Base64:
0hY8FK07NR8lUMp/w+Tj1qp2tiWbOP4taEaARnLitP/Alm5O5H2bw5==
     ↑      ↑    ↑        ↑         ↑
   chunk boundaries encode timing intervals

How it works:
┌────────────────────────────────────────────────┐
│ Timestamp Intervals → Chunk Sizes              │
│ 200ms (2 units) → 4 characters                 │
│ 400ms (4 units) → 6 characters                 │
│ 300ms (3 units) → 5 characters (boundary)      │
└────────────────────────────────────────────────┘

Visual:
[0hY8] [FK07NR] [8lUM] [p/w+Tj] [1qp2tiWb] ...
  ↑       ↑       ↑       ↑         ↑
  dit    dah     dit    boundary   dit...
```

#### Hex Dump Pattern Encoding
```
Message: "SOS"

Encoded as Hex Dump:
00000000  E9 64 8B 16
00000000  7A FF 9F 69
00000000  4C BA 7A 76 80 6A 16 7F
...

Byte groupings per line encode timing:
┌─────────────────────────────────────┐
│ 4 bytes  → 2 units (dit)            │
│ 8 bytes  → 4 units (dah)            │
│ 10 bytes → 5 units (dit + gap)      │
└─────────────────────────────────────┘

Pattern:
Line 1: 4 bytes  → dit
Line 2: 4 bytes  → dit
Line 3: 8 bytes  → dit + boundary
Line 4: 8 bytes  → dah
...
```

#### UTF-8 Text with Word Lengths
```
Message: "HIDE"

Encoded as Technical Text:
"data, data data process"
  ↑     ↑    ↑      ↑
  4ch   4ch  4ch   7ch

Word lengths encode timing intervals:
┌──────────────────────────────────────┐
│ 4 letters → 2 units (dit)            │
│ 6 letters → 4 units (dah)            │
│ comma     → letter boundary          │
│ period    → word boundary            │
└──────────────────────────────────────┘

Multi-Layer Encoding:
Layer 1: Word lengths = timing
Layer 2: Punctuation = morse boundaries
Layer 3: Character mapping = cipher key
```

### 🌐 Network Covert Channels

Hide messages in realistic network traffic patterns:

#### DNS Query Timing Channel
```
Message: "SOS"

DNS Query Log (looks like normal CDN lookups):
0ms      A data0.api-cdn.example.com → 187.240.43.159
200ms    A cdn1-prod.api-cdn.example.com → 57.209.161.185
400ms    A data2.api-cdn.example.com → 117.193.44.140

Timing Analysis:
┌────────────────────────────────────────────┐
│ Query 0 → Query 1: 200ms = dit            │
│ Query 1 → Query 2: 200ms = dit            │
│ Query 2 → Query 3: 500ms = dit + gap      │
│                                            │
│ Subdomain patterns reinforce encoding:    │
│ • "data*" = dit signals                   │
│ • "cdn*-prod" = dah signals               │
│ • "api-v*" = word boundary                │
└────────────────────────────────────────────┘

Visual Timeline:
0        200      400      900      1300
|        |        |        |        |
data0    cdn1     data2    cdn3     data4
(dit)    (dah)    (dit)    (gap)    (dah)
```

#### HTTP Request Timing Channel
```
Message: "HI"

HTTP Request Log (looks like API monitoring):
0ms      GET /v1/health
200ms    GET /v1/ping
500ms    GET /v1/health
700ms    GET /v1/metrics

Encoding Scheme:
┌────────────────────────────────────────┐
│ Intervals between requests:            │
│ 200ms (2 units) → dit → /health        │
│ 400ms (4 units) → dah → /metrics       │
│ 300ms (3 units) → gap → /status        │
│                                        │
│ Endpoint selection adds redundancy     │
└────────────────────────────────────────┘

Pattern Detection Difficulty:
• All endpoints legitimate ✓
• Response times vary naturally ✓
• Polling pattern seems regular ✓
• Requires statistical timing analysis to detect
```

#### TCP Connection Timing Channel
```
Message: "OK"

TCP Connection Log (looks like normal services):
0ms      10.0.88.243:60695 → service.com:80
500ms    10.0.230.217:49295 → service.com:6379
800ms    10.0.175.211:17341 → service.com:443

Port Selection Encoding:
┌────────────────────────────────────────┐
│ Dit ports: 80, 443, 8080 (HTTP/HTTPS) │
│ Dah ports: 22, 3306, 5432 (SSH, DB)   │
│ Gap ports: 53, 123, 389 (DNS, NTP)    │
└────────────────────────────────────────┘

Multi-Layer Encoding:
Layer 1: Connection timing = primary signal
Layer 2: Port selection = signal type indicator
Layer 3: Source IP patterns = checksum (optional)

Stealth Features:
• All ports commonly used ✓
• Connection attempts expected ✓
• Timing appears as network jitter ✓
```

#### ICMP Ping Covert Channel
```
Message: "SOS"

Ping Log (looks like network monitoring):
0ms      ping 8.8.8.8 seq=0 ttl=64 size=48 time=9ms
400ms    ping 8.8.8.8 seq=1 ttl=64 size=48 time=22ms
800ms    ping 8.8.8.8 seq=2 ttl=64 size=72 time=8ms

Encoding in Multiple Dimensions:
┌────────────────────────────────────────┐
│ Primary: Ping timing intervals         │
│ Secondary: Payload size variations     │
│                                        │
│ 32 bytes  → dit baseline               │
│ 64 bytes  → dah baseline               │
│ +8 bytes  → adds timing unit indicator │
└────────────────────────────────────────┘

Example:
48 bytes = 32 + 16 = 32 + (2×8) = dit + 2 units
72 bytes = 32 + 40 = 32 + (5×8) = dit + 5 units
                                  (dit + gap)

Detection Resistance:
• Regular ping monitoring normal ✓
• Payload size variations acceptable ✓
• TTL and sequence numbers standard ✓
```

#### WebSocket Frame Timing Channel
```
Message: "HI"

WebSocket Frame Log (looks like keepalive):
0ms      text {"type":"pong"}
300ms    text {"type":"heartbeat","interval":30000}
600ms    text {"type":"pong"}

Frame Type Encoding:
┌────────────────────────────────────────┐
│ "pong" → dit signal                    │
│ "heartbeat" → dah signal               │
│ "sync" → word boundary                 │
│                                        │
│ Frame timing carries primary message   │
│ Frame type provides redundancy/verify  │
└────────────────────────────────────────┘

Advantages:
• Persistent connection expected ✓
• Keepalive messages required ✓
• JSON payloads look legitimate ✓
• Timing variations normal for WebSocket
```

### 🎵 Music Encoding

Encode messages into musical structures using MIDI:

#### Multi-Layer Musical Steganography
```
Message: "HELLO"

Encoded as MIDI Music:
Note Sequence: C4 E4 G4 F4 A4 G4 C5 B4...
    ↑    ↑    ↑    ↑    ↑    ↑
    H    E    L    L    O    (space)

Encoding Layers:
┌────────────────────────────────────────────┐
│ Layer 1 (Pitch): Character-to-note mapping │
│ Layer 2 (Rhythm): Duration patterns        │
│ Layer 3 (Velocity): Dynamics variations    │
│ Layer 4 (Harmony): Chord progressions      │
└────────────────────────────────────────────┘

Detection Analysis:
• Pitch Entropy: 2.8 bits (normal: 1.5-3.0)
• Rhythm Regularity: 0.6 (suspicious if > 0.7)
• Interval Distribution: Natural-looking
• Overall Suspicion: 0.45 (Medium)
```

Features:
- **Pitch Encoding**: Maps characters to musical notes
- **Rhythm Encoding**: Binary data in note durations
- **Interval Encoding**: Melodic intervals carry information
- **Harmonic Camouflage**: Chords make music sound natural
- **Forensic Analysis**: Statistical detection methods
- **Auto-detection**: Identifies encoding mode used

## Use Cases

This is a **demonstration and exploration project** for:

- **Covert Communication**: Information embedded in event timing
- **API Call Scheduling**: Messages encoded in the timing of legitimate API requests
- **IoT Sensor Networks**: Data transmitted through sensor polling intervals
- **Network Traffic Analysis**: Understanding timing-based communication patterns
- **Steganography Research**: Hiding data in plain sight
- **Educational**: Teaching information theory and encoding concepts
- **Security Research**: Understanding and detecting covert channels
- **Research**: Exploring alternative communication channels
- unrelated: https://github.com/justin4957/logflow-anomaly-detector

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/temporal_encoder.git
cd temporal_encoder

# Install dependencies
mix deps.get

# Run tests
mix test
```

## Usage

### Basic Encoding and Decoding

```elixir
# Encode a message to timestamps
{:ok, timestamps} = TemporalEncoder.encode("HELLO",
  format: :relative,
  base_unit_ms: 100
)

# Decode timestamps back to text
{:ok, decoded_text} = TemporalEncoder.decode(timestamps, base_unit_ms: 100)
```

### Running the Demos

```bash
# Basic usage examples
mix run examples/basic_usage.exs

# API timing covert channel
mix run examples/api_timing_demo.exs

# Steganographic encoding
mix run examples/steganographic_encoding_demo.exs

# Network covert channels
mix run examples/network_covert_channel_demo.exs

# Music encoding with detection analysis (NEW!)
mix run examples/music_encoding_demo.exs
```

### Scheduling API Calls

```elixir
# Schedule HTTP requests at precise timestamps
{:ok, timestamps} = TemporalEncoder.encode("SECRET MESSAGE")

# Schedule requests - the timing carries the message
TemporalEncoder.Scheduler.schedule_http_requests(
  timestamps,
  "https://api.example.com/ping",
  callback: fn response ->
    IO.inspect(response.status)
  end
)
```

### Custom Timing

```elixir
# Use different base unit for faster/slower transmission
{:ok, timestamps} = TemporalEncoder.encode("HELLO", base_unit_ms: 50)

# Analyze timing information
{:ok, info} = TemporalEncoder.info("HELLO")
IO.inspect(info)
# => %{
#   signal_count: 17,
#   duration_ms: 4700,
#   morse_code: ".... . .-.. .-.. ---",
#   ...
# }
```

### Music Encoding and Analysis

```elixir
alias TemporalEncoder.{MusicEncoder, MusicDecoder, MusicAnalyzer}

# Encode a message to MIDI
{:ok, midi_data} = MusicEncoder.encode("HELLO WORLD",
  encoding_mode: :multi_layer,  # :pitch, :rhythm, :interval, or :multi_layer
  add_harmony: true,             # Add chord progressions for naturalness
  tempo: 120,
  key: :c_major
)

# Save to MIDI file
File.write!("message.mid", midi_data)

# Decode MIDI back to text
{:ok, decoded_text} = MusicDecoder.decode(midi_data,
  encoding_mode: :auto_detect,  # Automatically detect encoding method
  key: :c_major
)

# Analyze for steganographic content (security research)
{:ok, analysis} = MusicAnalyzer.analyze_file(midi_data)
IO.inspect(analysis.overall_suspicion_score)  # 0.0 = natural, 1.0 = suspicious
IO.inspect(analysis.risk_level)               # :minimal, :low, :medium, :high

# Generate forensic report
report = MusicAnalyzer.generate_report(analysis)
IO.puts(report)

# Compare to natural music baseline
{:ok, comparison} = MusicAnalyzer.compare_to_natural_music(midi_data)
IO.inspect(comparison.overall_deviation)
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     TemporalEncoder                         │
│                   (Main API Module)                         │
└──────────────┬────────────────────────┬─────────────────────┘
               │                        │
       ┌───────▼────────┐      ┌───────▼────────┐
       │ MorseEncoder   │      │    Decoder     │
       │                │      │                │
       │ Text → Morse   │      │ Timestamps →   │
       └───────┬────────┘      │ Text           │
               │               └───────▲────────┘
       ┌───────▼────────┐              │
       │   Timestamp    │──────────────┘
       │   Generator    │
       │                │
       │ Morse →        │
       │ Timestamps     │
       └───────┬────────┘
               │
       ┌───────▼────────┐
       │   Scheduler    │
       │                │
       │ Executes at    │
       │ precise times  │
       └────────────────┘
```

## Technical Details

### Interval Disambiguation

The key insight is that each interval encodes information about the **previous** timestamp, not the next one. This allows for unambiguous decoding:

```
Timestamp 1 → Interval A → Timestamp 2 → Interval B → Timestamp 3 → Final
              ↓                          ↓                          ↓
         Tells us what              Tells us what             Marks end of
         TS1 was                   TS2 was                    TS3 signal
```

The final timestamp marks where the last signal ends, allowing the decoder to calculate the duration and type of the final signal.

### Boundary Markers

Letter and word boundaries are encoded as gaps (intervals with no timestamp):
- **3-unit gap**: Separates letters within a word
- **6-unit gap**: Separates words

This creates distinct interval patterns that can't be confused with morse signals.

### Timing Precision Requirements

```
┌──────────────────────────────────────────────┐
│ Base Unit    Tolerance    Use Case          │
├──────────────────────────────────────────────┤
│ 50ms         ±15ms        Fast local comms  │
│ 100ms        ±30ms        Standard encoding  │
│ 200ms        ±60ms        Network timing     │
│ 500ms        ±150ms       Slow covert chan.  │
└──────────────────────────────────────────────┘

Detection Resistance vs Speed Trade-off:
Faster → More detectable, higher bandwidth
Slower → Less detectable, lower bandwidth
```

## Detection and Countermeasures

### Detection Indicators

**Statistical Anomalies:**
- Non-random timing intervals
- Periodic patterns in network traffic
- Correlation between timing and other attributes
- Entropy analysis reveals structure

**Protocol-Specific:**
- DNS: Unusual query patterns, subdomain structures
- HTTP: Request timing doesn't match expected behavior
- TCP: Port selection correlates with timing
- ICMP: Payload sizes follow patterns

### Countermeasures

**For Detection:**
```
1. Timing entropy analysis
2. Statistical pattern recognition (ML-based)
3. Baseline behavioral modeling
4. Protocol-specific anomaly detection
5. Traffic normalization and padding
```

**For Stealth Improvement:**
```
1. Add random timing jitter within tolerance
2. Mix with legitimate high-volume traffic
3. Use multiple encoding layers
4. Spread across different protocols
5. Implement adaptive timing based on network conditions
```

## Performance Characteristics

```
Message Length:  10 characters
Base Unit:       100ms
Total Signals:   ~30-50 (depends on morse encoding)
Duration:        ~5-10 seconds
Bandwidth:       ~1-2 characters/second
Efficiency:      ~4.7 bits per signal

Comparison to Traditional Encoding:
• ASCII: 8 bits per character = 80 bits for 10 chars
• Temporal: ~200-300 signals = ~200-300 time events
• Trade-off: Lower efficiency for covert capability
```

## Limitations

- **Timing Precision**: Requires relatively precise event timing (millisecond accuracy)
- **Latency**: Not suitable for real-time communication due to temporal encoding overhead
- **Detection**: Traffic analysis can identify timing patterns with sufficient data
- **Efficiency**: Less efficient than traditional encoding for bulk data transfer
- **Jitter Sensitivity**: Network timing variations can cause decoding errors
- **Bandwidth**: Very low data rate compared to traditional channels

## Educational Value

This project demonstrates:
- Information theory principles (channel capacity, encoding schemes)
- Temporal pattern recognition and signal processing
- Steganography and data hiding techniques
- Covert channel communication methods
- Network timing analysis and detection
- Morse code timing standards and applications
- Alternative communication channels and side channels
- Statistical anomaly detection techniques

## Demo Comparisons

| Demo | Stealth Level | Complexity | Use Case |
|------|--------------|------------|----------|
| **API Timing** | ⭐⭐⭐ Medium | ⭐⭐ Simple | Basic covert comms |
| **Steganographic** | ⭐⭐⭐⭐ High | ⭐⭐⭐⭐ Complex | Data exfiltration |
| **Network Covert** | ⭐⭐⭐⭐⭐ Very High | ⭐⭐⭐⭐⭐ Very Complex | Advanced persistence |

## Contributing

This is an exploratory project. Contributions, ideas, and experiments are welcome!

Areas for contribution:
- Additional encoding schemes
- Improved error correction
- Detection algorithms
- New covert channel demonstrations
- Performance optimizations
- Statistical analysis tools

## License

MIT License - See LICENSE file for details

## Disclaimer

This project is for **educational and research purposes only**. Use responsibly and in accordance with applicable laws and regulations. The authors are not responsible for misuse of this technology.

**Important Notes:**
- Obtain proper authorization before testing on any network
- Use only in controlled environments
- Follow responsible disclosure practices
- Comply with all applicable laws and regulations
- Respect privacy and security policies

## Acknowledgments

Inspired by:
- International Morse Code timing standards
- Timing-based covert channel research
- Information theory and alternative communication methods
- Steganography and data hiding techniques
- Network security and traffic analysis research

## References

- [Covert Channels in TCP/IP Protocol Stack](https://example.com)
- [Timing Attacks on Web Privacy](https://example.com)
- [Information Hiding Techniques for Steganography](https://example.com)
- [Morse Code Timing Standards (ITU-R M.1677)](https://example.com)

---

**⚠️ Security Researchers**: This tool is provided for defensive security research and education. Always obtain proper authorization before security testing.
