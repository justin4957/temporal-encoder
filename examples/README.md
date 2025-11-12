# Temporal Encoder Examples

This directory contains demonstration scripts showing various creative applications of temporal encoding.

## Available Demos

### 1. Basic Usage (`basic_usage.exs`)
Demonstrates the core functionality of the temporal encoder:
- Simple encoding/decoding
- Message information
- Different timing speeds
- Scheduling with callbacks
- Timing analysis
- Character support

**Run:** `mix run examples/basic_usage.exs`

### 2. API Timing Demo (`api_timing_demo.exs`)
Shows how to encode messages in the timing of API calls:
- Sender encodes message into timestamps
- Simulates API requests at encoded times
- Receiver extracts timestamps from logs
- Decodes message from timing patterns

**Featured Message:** "MEET AT NOON"

**Run:** `mix run examples/api_timing_demo.exs`

### 3. Steganographic Encoding Demo (`steganographic_encoding_demo.exs`)
**NEW!** Advanced demonstration of hiding morse code and cipher data within plausible-looking formats:

#### Techniques Demonstrated:

1. **Base64 Structure Encoding**
   - Timing embedded in chunk sizes and boundaries
   - Produces valid-looking base64 data
   - Message hidden in structural patterns

2. **Hex Dump Pattern Encoding**
   - Timing in byte grouping patterns per line
   - Appears as normal memory dumps or packet captures
   - Non-random groupings reveal message

3. **UTF-8 Text with Embedded Patterns**
   - Timing encoded in word lengths
   - Morse code in punctuation placement
   - Simple substitution cipher overlay
   - Reads as plausible technical documentation

4. **Multi-Layer Encoding**
   - Combines visual data (API response format)
   - Timing in response headers
   - Morse code in HTTP status sequences
   - ROT13 cipher applied to message
   - Maximum steganographic effect

**Featured Messages:** "HIDE", "SECRET MESSAGE", "DEAD DROP AT NOON"

**Run:** `mix run examples/steganographic_encoding_demo.exs`

**Example Output:**
```
Encoded in base64 structure:
  0hY8FK07NR8lUMp/w+Tj1qp2tiWbOP4taEaARnLitP/Alm5O5H2bw5==

Encoded as hex dump:
  00000000  E9 64 8B 16
  00000000  7A FF 9F 69
  ...

Encoded in UTF-8 text:
  data, data data process
```

### 4. Network Covert Channel Demo (`network_covert_channel_demo.exs`)
**NEW!** Demonstrates encoding messages in realistic network traffic patterns:

#### Covert Channels:

1. **DNS Query Timing Channel**
   - Subdomains encode morse patterns
   - Query timing carries message
   - Appears as normal CDN lookups
   - Example: `cdn1-prod.api-cdn.example.com`

2. **HTTP API Request Timing**
   - Request intervals encode message
   - Endpoint selection varies by pattern
   - Looks like legitimate API monitoring
   - Uses realistic service endpoints

3. **TCP Connection Timing Channel**
   - Connection timing and port selection
   - Common legitimate ports (80, 443, 22, etc.)
   - Appears as normal service connections
   - Port patterns indicate signal types

4. **ICMP Ping Covert Channel**
   - Ping timing intervals encode message
   - Payload sizes vary by interval units
   - Looks like network monitoring
   - TTL and sequence numbers realistic

5. **WebSocket Frame Timing**
   - Frame timing and type selection
   - Appears as keepalive/heartbeat messages
   - Frame payloads look legitimate
   - JSON message formats

**Featured Messages:** "SOS", "EXFIL DATA", "HIDE"

**Run:** `mix run examples/network_covert_channel_demo.exs`

**Example Output:**
```
DNS Query Log:
  0ms      A data0.api-cdn.example.com → 187.240.43.159
  200ms    A cdn1-prod.api-cdn.example.com → 57.209.161.185

HTTP Request Log:
  0ms      GET https://api.service.io/v1/health
  300ms    GET https://api.service.io/v1/health

TCP Connection Log:
  0ms      10.0.88.243:60695 → services.cloud.provider.com:80
  200ms    10.0.230.217:49295 → services.cloud.provider.com:6379

ICMP Ping Log:
  0ms      ping 8.8.8.8 seq=0 ttl=64 size=48 time=9ms
  400ms    ping 8.8.8.8 seq=1 ttl=64 size=48 time=22ms

WebSocket Frame Log:
  0ms      text {"type":"pong"}
  300ms    text {"type":"heartbeat","interval":30000}
```

## Key Concepts

### Temporal Encoding
All demos use the same underlying principle:
- **Information is carried entirely in timing**
- No payload data reveals the message
- Timing intervals encode morse code patterns
- Multiple layers can be combined for stealth

### Morse Code Timing
Standard intervals (base unit = 100ms):
- **2 units (200ms)**: dit (.)
- **3 units (300ms)**: letter boundary
- **4 units (400ms)**: dah (-)
- **6 units (600ms)**: word boundary
- **Combined intervals** for efficiency

### Detection Challenges
The advanced demos highlight:
- All formats appear syntactically valid
- Statistical analysis required to detect patterns
- Multiple encoding layers increase complexity
- Timing analysis needed to extract full message

## Educational Purpose

These demos are for **educational and research purposes only**:
- Understanding information theory
- Exploring covert communication channels
- Studying timing-based encoding
- Network traffic analysis training
- Security research and detection techniques

## Use Responsibly

All demonstrations should be used:
- In authorized testing environments only
- For educational purposes
- With full permission and authorization
- In compliance with applicable laws
- For defensive security research

## Next Steps

Try modifying the demos to:
- Add timing jitter for increased stealth
- Combine multiple encoding techniques
- Implement error correction
- Add encryption layers
- Create custom encoding schemes
- Build detection tools
- Experiment with different base units
- Mix with high-volume legitimate traffic
