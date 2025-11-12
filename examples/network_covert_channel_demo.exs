#!/usr/bin/env elixir

# Network Covert Channel Demo
# Demonstrates encoding messages in network traffic patterns, DNS queries,
# and protocol timing that appear as normal network behavior

defmodule NetworkCovertChannel do
  @moduledoc """
  Encodes secret messages into network traffic patterns.
  All traffic appears legitimate but carries hidden timing-based information.
  """

  @doc """
  Encodes message in DNS query timing and subdomain structure.
  Example: Multiple DNS queries to legitimate-looking subdomains
  """
  def encode_in_dns_queries(message, opts \\ []) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, 100)
    base_domain = Keyword.get(opts, :domain, "api-cdn.example.com")

    {:ok, timestamps} = TemporalEncoder.encode(message, format: :relative, base_unit_ms: base_unit_ms)
    {:ok, morse_patterns} = TemporalEncoder.MorseEncoder.encode(message)

    # Generate DNS queries where subdomain fragments encode morse patterns
    queries = morse_patterns
    |> Enum.with_index()
    |> Enum.map(fn {pattern, idx} ->
      # Convert morse to subdomain segments
      subdomain = cond do
        pattern == "/" -> "api-v2"  # Word boundary = version indicator
        String.contains?(pattern, "---") -> "cdn#{idx}-prod"  # Many dahs
        String.contains?(pattern, "--") -> "cache#{idx}"      # Some dahs
        true -> "data#{idx}"  # Dits
      end

      timestamp = Enum.at(timestamps, idx, 0)

      %{
        timestamp_ms: timestamp,
        query: "#{subdomain}.#{base_domain}",
        type: "A",
        response: generate_ip(),
        ttl: 300
      }
    end)

    %{
      message: message,
      queries: queries,
      timestamps: timestamps,
      morse: Enum.join(morse_patterns, " "),
      note: "Message encoded in DNS query timing and subdomain patterns"
    }
  end

  @doc """
  Encodes message in HTTP request timing with realistic API patterns.
  Requests look like normal API polling but timing carries the message.
  """
  def encode_in_http_requests(message, opts \\ []) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, 150)
    api_endpoint = Keyword.get(opts, :endpoint, "https://api.service.io/v1")

    {:ok, timestamps} = TemporalEncoder.encode(message, format: :relative, base_unit_ms: base_unit_ms)

    intervals = calculate_intervals(timestamps)

    # Generate HTTP requests that look like normal API usage
    requests = Enum.with_index(timestamps)
    |> Enum.map(fn {ts, idx} ->
      # Choose endpoint based on timing interval pattern
      endpoint_path = case Enum.at(intervals, idx) do
        nil -> "/status"
        interval when interval > 300 -> "/metrics"
        interval when interval > 200 -> "/health"
        _ -> "/ping"
      end

      %{
        timestamp_ms: ts,
        method: "GET",
        url: "#{api_endpoint}#{endpoint_path}",
        headers: [
          {"User-Agent", "ServiceMonitor/2.1.0"},
          {"Accept", "application/json"},
          {"X-Request-ID", generate_request_id()}
        ],
        status: 200,
        response_time: :rand.uniform(50) + 20
      }
    end)

    %{
      message: message,
      requests: requests,
      timestamps: timestamps,
      note: "Message encoded in HTTP request timing; endpoints vary by interval pattern"
    }
  end

  @doc """
  Encodes message in TCP connection timing and port patterns.
  Multiple connections to legitimate ports at specific intervals.
  """
  def encode_in_tcp_connections(message, opts \\ []) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, 100)
    target_host = Keyword.get(opts, :host, "services.cloud.provider.com")

    {:ok, timestamps} = TemporalEncoder.encode(message, format: :relative, base_unit_ms: base_unit_ms)
    {:ok, morse_patterns} = TemporalEncoder.MorseEncoder.encode(message)

    # Common legitimate ports
    ports = %{
      dit: [80, 443, 8080, 8443],          # HTTP/HTTPS
      dah: [22, 3306, 5432, 6379],         # SSH, MySQL, PostgreSQL, Redis
      word: [53, 123, 389, 636]            # DNS, NTP, LDAP
    }

    # Generate TCP connections
    connections = morse_patterns
    |> Enum.with_index()
    |> Enum.map(fn {pattern, idx} ->
      port = cond do
        pattern == "/" -> Enum.random(ports.word)
        String.contains?(pattern, "-") -> Enum.random(ports.dah)
        true -> Enum.random(ports.dit)
      end

      timestamp = Enum.at(timestamps, idx, 0)

      %{
        timestamp_ms: timestamp,
        src_ip: "10.0.#{:rand.uniform(255)}.#{:rand.uniform(255)}",
        dst_ip: target_host,
        src_port: :rand.uniform(60000) + 1024,
        dst_port: port,
        protocol: "TCP",
        flags: "SYN",
        seq: :rand.uniform(4_294_967_295)
      }
    end)

    %{
      message: message,
      connections: connections,
      timestamps: timestamps,
      morse: Enum.join(morse_patterns, " "),
      note: "Message encoded in TCP connection timing; port selection indicates signal type"
    }
  end

  @doc """
  Encodes message in ICMP ping timing (ping covert channel).
  Regular-looking ping traffic with hidden message in timing.
  """
  def encode_in_icmp_pings(message, opts \\ []) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, 200)
    target = Keyword.get(opts, :target, "8.8.8.8")

    {:ok, timestamps} = TemporalEncoder.encode(message, format: :relative, base_unit_ms: base_unit_ms)

    intervals = calculate_intervals(timestamps)

    # Generate ICMP echo requests
    pings = Enum.with_index(timestamps)
    |> Enum.map(fn {ts, idx} ->
      # Vary payload size based on interval (adds another encoding layer)
      interval = Enum.at(intervals, idx, 200)
      units = round(interval / base_unit_ms)
      payload_size = 32 + (units * 8)  # 32-80 bytes

      %{
        timestamp_ms: ts,
        type: "ECHO_REQUEST",
        target: target,
        sequence: idx,
        ttl: 64,
        payload_size: payload_size,
        rtt: :rand.uniform(20) + 5
      }
    end)

    %{
      message: message,
      pings: pings,
      timestamps: timestamps,
      note: "Message encoded in ICMP ping timing; payload sizes vary by interval units"
    }
  end

  @doc """
  Encodes message in WebSocket frame timing.
  Appears as normal WebSocket heartbeat/keepalive messages.
  """
  def encode_in_websocket_frames(message, opts \\ []) do
    base_unit_ms = Keyword.get(opts, :base_unit_ms, 150)

    {:ok, timestamps} = TemporalEncoder.encode(message, format: :relative, base_unit_ms: base_unit_ms)
    {:ok, morse_patterns} = TemporalEncoder.MorseEncoder.encode(message)

    # Generate WebSocket frames
    frames = morse_patterns
    |> Enum.with_index()
    |> Enum.map(fn {pattern, idx} ->
      timestamp = Enum.at(timestamps, idx, 0)

      # Frame type based on morse pattern
      {opcode, payload} = cond do
        pattern == "/" -> {:text, ~s({"type":"sync","status":"idle"})}
        String.contains?(pattern, "---") ->
          {:text, ~s({"type":"heartbeat","interval":30000})}
        String.contains?(pattern, "--") ->
          {:text, ~s({"type":"ping","timestamp":#{System.system_time(:millisecond)}})}
        true ->
          {:text, ~s({"type":"pong"})}
      end

      %{
        timestamp_ms: timestamp,
        opcode: opcode,
        fin: true,
        masked: true,
        payload: payload,
        length: byte_size(payload)
      }
    end)

    %{
      message: message,
      frames: frames,
      timestamps: timestamps,
      morse: Enum.join(morse_patterns, " "),
      note: "Message encoded in WebSocket frame timing; frame types indicate signal patterns"
    }
  end

  @doc """
  Creates a network packet capture (PCAP-style) output showing all traffic.
  """
  def generate_pcap_style_output(traffic_data) do
    traffic_data
    |> Enum.with_index()
    |> Enum.map(fn {packet, idx} ->
      format_packet(idx, packet)
    end)
    |> Enum.join("\n")
  end

  # Helper functions

  defp calculate_intervals([]), do: []
  defp calculate_intervals([_]), do: []
  defp calculate_intervals(timestamps) do
    timestamps
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [a, b] -> b - a end)
  end

  defp generate_ip do
    "#{:rand.uniform(255)}.#{:rand.uniform(255)}.#{:rand.uniform(255)}.#{:rand.uniform(255)}"
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end

  defp format_packet(idx, packet) do
    ts = packet.timestamp_ms || packet[:timestamp_ms] || 0
    time_str = "#{div(ts, 1000)}.#{rem(ts, 1000) |> to_string() |> String.pad_leading(3, "0")}"

    cond do
      Map.has_key?(packet, :query) ->
        "#{idx} #{time_str}s DNS Query: #{packet.query} → #{packet.response}"

      Map.has_key?(packet, :url) ->
        "#{idx} #{time_str}s HTTP #{packet.method} #{packet.url} (#{packet.status})"

      Map.has_key?(packet, :dst_port) ->
        "#{idx} #{time_str}s TCP #{packet.src_ip}:#{packet.src_port} → #{packet.dst_ip}:#{packet.dst_port}"

      Map.has_key?(packet, :target) and packet.type == "ECHO_REQUEST" ->
        "#{idx} #{time_str}s ICMP Echo Request to #{packet.target}, seq=#{packet.sequence}, size=#{packet.payload_size}"

      Map.has_key?(packet, :opcode) ->
        "#{idx} #{time_str}s WebSocket #{packet.opcode} frame, len=#{packet.length}"

      true ->
        "#{idx} #{time_str}s Unknown packet"
    end
  end
end

# Demo Execution

IO.puts("\n╔═══════════════════════════════════════════════════════════╗")
IO.puts("║        NETWORK COVERT CHANNEL DEMONSTRATION              ║")
IO.puts("║   Hiding Messages in Legitimate Network Traffic          ║")
IO.puts("╚═══════════════════════════════════════════════════════════╝\n")

messages = [
  {"SOS", "Emergency signal hidden in network traffic"},
  {"EXFIL DATA", "Data exfiltration command"}
]

Enum.each(messages, fn {message, description} ->
  IO.puts("\n" <> String.duplicate("═", 60))
  IO.puts("SECRET MESSAGE: \"#{message}\"")
  IO.puts("SCENARIO: #{description}")
  IO.puts(String.duplicate("═", 60))

  # Technique 1: DNS Covert Channel
  IO.puts("\n▶ TECHNIQUE 1: DNS Query Timing Channel")
  IO.puts("━" <> String.duplicate("─", 58))

  dns = NetworkCovertChannel.encode_in_dns_queries(message, base_unit_ms: 100)
  IO.puts("\nDNS Query Log (appears as normal CDN lookups):")
  dns.queries
  |> Enum.take(6)
  |> Enum.each(fn q ->
    IO.puts("  #{String.pad_trailing(to_string(q.timestamp_ms) <> "ms", 8)} #{q.type} #{q.query} → #{q.response}")
  end)
  if length(dns.queries) > 6 do
    IO.puts("  ... (#{length(dns.queries) - 6} more queries)")
  end

  IO.puts("\nHidden Information:")
  IO.puts("  • Original Message: #{dns.message}")
  IO.puts("  • Morse Code: #{dns.morse}")
  IO.puts("  • #{dns.note}")

  # Technique 2: HTTP Request Timing
  IO.puts("\n▶ TECHNIQUE 2: HTTP API Request Timing Channel")
  IO.puts("━" <> String.duplicate("─", 58))

  http = NetworkCovertChannel.encode_in_http_requests(message, base_unit_ms: 150)
  IO.puts("\nHTTP Request Log (appears as normal API monitoring):")
  http.requests
  |> Enum.take(6)
  |> Enum.each(fn r ->
    IO.puts("  #{String.pad_trailing(to_string(r.timestamp_ms) <> "ms", 8)} #{r.method} #{r.url}")
  end)
  if length(http.requests) > 6 do
    IO.puts("  ... (#{length(http.requests) - 6} more requests)")
  end

  IO.puts("\nHidden Information:")
  IO.puts("  • Original Message: #{http.message}")
  IO.puts("  • #{http.note}")

  # Technique 3: TCP Connection Timing
  IO.puts("\n▶ TECHNIQUE 3: TCP Connection Timing Channel")
  IO.puts("━" <> String.duplicate("─", 58))

  tcp = NetworkCovertChannel.encode_in_tcp_connections(message, base_unit_ms: 100)
  IO.puts("\nTCP Connection Log (appears as normal service connections):")
  tcp.connections
  |> Enum.take(6)
  |> Enum.each(fn c ->
    IO.puts("  #{String.pad_trailing(to_string(c.timestamp_ms) <> "ms", 8)} #{c.src_ip}:#{c.src_port} → #{c.dst_ip}:#{c.dst_port}")
  end)
  if length(tcp.connections) > 6 do
    IO.puts("  ... (#{length(tcp.connections) - 6} more connections)")
  end

  IO.puts("\nHidden Information:")
  IO.puts("  • Original Message: #{tcp.message}")
  IO.puts("  • Morse Code: #{tcp.morse}")
  IO.puts("  • #{tcp.note}")

  # Technique 4: ICMP Ping Timing
  IO.puts("\n▶ TECHNIQUE 4: ICMP Ping Covert Channel")
  IO.puts("━" <> String.duplicate("─", 58))

  icmp = NetworkCovertChannel.encode_in_icmp_pings(message, base_unit_ms: 200)
  IO.puts("\nICMP Ping Log (appears as normal network monitoring):")
  icmp.pings
  |> Enum.take(6)
  |> Enum.each(fn p ->
    IO.puts("  #{String.pad_trailing(to_string(p.timestamp_ms) <> "ms", 8)} ping #{p.target} seq=#{p.sequence} ttl=#{p.ttl} size=#{p.payload_size} time=#{p.rtt}ms")
  end)
  if length(icmp.pings) > 6 do
    IO.puts("  ... (#{length(icmp.pings) - 6} more pings)")
  end

  IO.puts("\nHidden Information:")
  IO.puts("  • Original Message: #{icmp.message}")
  IO.puts("  • #{icmp.note}")

  # Technique 5: WebSocket Frame Timing
  if String.length(message) < 15 do  # Keep output manageable
    IO.puts("\n▶ TECHNIQUE 5: WebSocket Frame Timing Channel")
    IO.puts("━" <> String.duplicate("─", 58))

    ws = NetworkCovertChannel.encode_in_websocket_frames(message, base_unit_ms: 150)
    IO.puts("\nWebSocket Frame Log (appears as keepalive messages):")
    ws.frames
    |> Enum.each(fn f ->
      IO.puts("  #{String.pad_trailing(to_string(f.timestamp_ms) <> "ms", 8)} #{f.opcode} #{f.payload}")
    end)

    IO.puts("\nHidden Information:")
    IO.puts("  • Original Message: #{ws.message}")
    IO.puts("  • Morse Code: #{ws.morse}")
    IO.puts("  • #{ws.note}")
  end
end)

# Unified PCAP-style view
IO.puts("\n\n" <> String.duplicate("═", 60))
IO.puts("UNIFIED NETWORK CAPTURE VIEW")
IO.puts(String.duplicate("═", 60))

message = "HIDE"
IO.puts("\nMessage to hide: \"#{message}\"")
IO.puts("\nGenerating mixed traffic patterns...\n")

# Generate all types of traffic for the same message
dns_traffic = NetworkCovertChannel.encode_in_dns_queries(message, base_unit_ms: 100)
http_traffic = NetworkCovertChannel.encode_in_http_requests(message, base_unit_ms: 100)
tcp_traffic = NetworkCovertChannel.encode_in_tcp_connections(message, base_unit_ms: 100)

# Mix them together (simulating concurrent legitimate traffic)
all_traffic = (dns_traffic.queries ++ http_traffic.requests ++ tcp_traffic.connections)
|> Enum.shuffle()
|> Enum.take(15)

pcap_output = NetworkCovertChannel.generate_pcap_style_output(all_traffic)
IO.puts("Network Packet Capture (mixed protocols):")
IO.puts(String.duplicate("-", 60))
IO.puts(pcap_output)

IO.puts("\n" <> String.duplicate("═", 60))
IO.puts("DETECTION AND COUNTERMEASURES")
IO.puts(String.duplicate("═", 60))

IO.puts("""

DETECTION INDICATORS:
1. DNS Queries
   • Non-uniform timing intervals
   • Repeated queries to similar subdomains
   • Query patterns don't match typical CDN usage
   → Detection: Statistical analysis of query timing

2. HTTP Requests
   • Request timing doesn't match expected polling intervals
   • Unusual correlation between endpoints and timing
   • No response payload variation
   → Detection: Timing entropy analysis

3. TCP Connections
   • Port selection patterns correlate with timing
   • Connection attempts without data transfer
   • Rhythmic pattern in connection establishment
   → Detection: Port pattern and timing correlation

4. ICMP Pings
   • Payload size variation follows patterns
   • Timing intervals are non-random
   • No packet loss despite regular schedule
   → Detection: Ping timing and size pattern analysis

5. WebSocket Frames
   • Keepalive messages don't match typical intervals
   • Frame type selection follows patterns
   • Payload variation correlates with timing
   → Detection: Frame timing and type entropy

COUNTERMEASURES:
• Network timing jitter analysis
• Statistical pattern recognition (ML-based)
• Baseline behavioral modeling
• Protocol-specific anomaly detection
• Traffic normalization and padding

STEALTH IMPROVEMENTS:
• Add random timing noise within tolerance
• Mix with legitimate high-volume traffic
• Use multiple encoding layers
• Spread across different protocols
• Implement adaptive timing based on network conditions
""")

IO.puts("╔═══════════════════════════════════════════════════════════╗")
IO.puts("║  Demo Complete - Messages Hidden in Network Traffic      ║")
IO.puts("╚═══════════════════════════════════════════════════════════╝\n")
