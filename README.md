# Temporal Encoder

A demonstration application exploring novel communication methods through temporal patterns. This project encodes text messages into precisely-timed events, where information is carried entirely in the temporal spacing between signals rather than in the signals themselves.

## Concept

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

### Example: "HI MOM"

```
H (....): 4 timestamps at 0, 200, 400, 600ms
         + 300ms letter gap → 900ms
I (..):   2 timestamps at 900, 1100ms
         + 600ms word gap → 1700ms
M (--):   2 timestamps at 1700, 2100ms
         + 300ms letter gap → 2400ms
O (---):  3 timestamps at 2400, 2800, 3200ms
         + 300ms letter gap → 3500ms
M (--):   2 timestamps at 3500, 3900ms
```

The complete message is encoded in just the timestamps: `[0, 200, 400, 600, 1100, 1300, 2100, 2500, 3200, 3600, 4000, 4700, 5100]`

Decoding analyzes the intervals between timestamps to reconstruct the original message.

## Use Cases

This is a **demonstration and exploration project** for:

- **Covert Communication**: Information embedded in event timing
- **API Call Scheduling**: Messages encoded in the timing of legitimate API requests
- **IoT Sensor Networks**: Data transmitted through sensor polling intervals
- **Network Traffic Analysis**: Understanding timing-based communication patterns
- **Educational**: Teaching information theory and encoding concepts
- **Research**: Exploring alternative communication channels

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
#   signal_count: 14,
#   duration_ms: 2800,
#   ...
# }
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
Timestamp 1 → Interval A → Timestamp 2 → Interval B → Timestamp 3
              ↓                          ↓
         Tells us what              Tells us what
         TS1 was                   TS2 was
```

The last timestamp is inferred based on the pattern of the previous interval.

### Boundary Markers

Letter and word boundaries are encoded as gaps (intervals with no timestamp):
- **3-unit gap**: Separates letters within a word
- **6-unit gap**: Separates words

This creates distinct interval patterns that can't be confused with morse signals.

## Limitations

- **Timing Precision**: Requires relatively precise event timing (millisecond accuracy)
- **Latency**: Not suitable for real-time communication due to temporal encoding overhead
- **Detection**: Traffic analysis can identify timing patterns
- **Efficiency**: Less efficient than traditional encoding for bulk data transfer

## Educational Value

This project demonstrates:
- Information theory principles (channel capacity, encoding schemes)
- Temporal pattern recognition
- Signal processing concepts
- Practical application of morse code timing
- Alternative communication channels

## Contributing

This is an exploratory project. Contributions, ideas, and experiments are welcome!

## License

MIT License - See LICENSE file for details

## Disclaimer

This project is for **educational and research purposes only**. Use responsibly and in accordance with applicable laws and regulations. The authors are not responsible for misuse of this technology.

## Acknowledgments

Inspired by:
- International Morse Code timing standards
- Timing-based covert channel research
- Information theory and alternative communication methods
