#!/usr/bin/env bash
set -u

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/flow-map.sh <url-or-host[:port]>

Examples:
  ./scripts/flow-map.sh https://example.com
  ./scripts/flow-map.sh github.com:22

This script is read-only. It collects DNS, route, public IP, and trace
observations, then prints a Markdown report with a Mermaid flowchart.
USAGE
}

have() {
  command -v "$1" >/dev/null 2>&1
}

first_line() {
  sed -n '1p'
}

strip_url_to_hostport() {
  local input="$1"
  local without_scheme
  if [[ "$input" =~ ^[A-Za-z][A-Za-z0-9+.-]*:// ]]; then
    without_scheme="${input#*://}"
  else
    without_scheme="$input"
  fi
  without_scheme="${without_scheme%%/*}"
  without_scheme="${without_scheme%%\?*}"
  without_scheme="${without_scheme%%#*}"
  printf '%s\n' "$without_scheme"
}

host_from_hostport() {
  local hostport="$1"
  if [[ "$hostport" =~ ^\[.*\](:[0-9]+)?$ ]]; then
    printf '%s\n' "$hostport" | sed -E 's/^\[([^]]+)\](:[0-9]+)?$/\1/'
  else
    printf '%s\n' "${hostport%%:*}"
  fi
}

port_from_input() {
  local input="$1"
  local hostport="$2"
  if [[ "$hostport" =~ ^\[.*\]:([0-9]+)$ ]]; then
    printf '%s\n' "$hostport" | sed -E 's/^.*:([0-9]+)$/\1/'
  elif [[ "$hostport" == *:* && "$hostport" != *::* ]]; then
    printf '%s\n' "${hostport##*:}"
  elif [[ "$input" =~ ^https:// ]]; then
    printf '443\n'
  elif [[ "$input" =~ ^http:// ]]; then
    printf '80\n'
  else
    printf 'unknown\n'
  fi
}

resolve_a() {
  local host="$1"
  if have dig; then
    dig +short A "$host" | grep -E '^[0-9.]+$' | first_line
  elif have getent; then
    getent ahostsv4 "$host" | awk '{print $1; exit}'
  fi
}

resolve_aaaa() {
  local host="$1"
  if have dig; then
    dig +short AAAA "$host" | grep ':' | first_line
  elif have getent; then
    getent ahostsv6 "$host" | awk '{print $1; exit}'
  fi
}

route_get() {
  local ip="$1"
  if [[ -n "$ip" ]] && have ip; then
    ip route get "$ip" 2>/dev/null | first_line
  fi
}

route_field() {
  local route="$1"
  local key="$2"
  awk -v key="$key" '{
    for (i = 1; i <= NF; i++) {
      if ($i == key && (i + 1) <= NF) {
        print $(i + 1)
        exit
      }
    }
  }' <<<"$route"
}

public_ip() {
  local family="$1"
  if have curl; then
    curl "$family" -fsS --max-time 6 https://api.ipify.org 2>/dev/null || true
  fi
}

dns_servers() {
  if [[ -f /etc/resolv.conf ]]; then
    awk '/^nameserver[[:space:]]+/ {
      if (out != "") {
        out = out ", " $2
      } else {
        out = $2
      }
    }
    END {print out}' /etc/resolv.conf
  fi
}

trace_summary() {
  local ip="$1"
  if [[ -z "$ip" ]]; then
    return 0
  fi
  if have tracepath; then
    tracepath "$ip" 2>/dev/null | sed -n '1,12p'
  elif have traceroute; then
    traceroute "$ip" 2>/dev/null | sed -n '1,12p'
  else
    printf 'tracepath/traceroute not installed\n'
  fi
}

escape_mermaid() {
  printf '%s' "$1" | sed 's/"/\\"/g'
}

if [[ "${1:-}" == "" || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

input="$1"
hostport="$(strip_url_to_hostport "$input")"
host="$(host_from_hostport "$hostport")"
port="$(port_from_input "$input" "$hostport")"

target_a="$(resolve_a "$host" || true)"
target_aaaa="$(resolve_aaaa "$host" || true)"
route_target="$target_a"
if [[ -z "$route_target" ]]; then
  route_target="$target_aaaa"
fi

route="$(route_get "$route_target" || true)"
dev="$(route_field "$route" dev)"
src="$(route_field "$route" src)"
via="$(route_field "$route" via)"
dns="$(dns_servers)"
pub4="$(public_ip -4)"
pub6="$(public_ip -6)"
generated_at="$(date -Is)"

cat <<REPORT
# Network Flow Map

- Generated at: \`$generated_at\`
- Input: \`$input\`
- Host: \`$host\`
- Port: \`$port\`

## Summary

| Item | Value |
| --- | --- |
| Target A | \`${target_a:-not found}\` |
| Target AAAA | \`${target_aaaa:-not found}\` |
| DNS servers | \`${dns:-unknown}\` |
| Public IPv4 | \`${pub4:-unavailable}\` |
| Public IPv6 | \`${pub6:-unavailable}\` |
| Route target | \`${route_target:-unavailable}\` |
| Route interface | \`${dev:-unknown}\` |
| Source address | \`${src:-unknown}\` |
| Next hop | \`${via:-direct or unknown}\` |

## Route Lookup

\`\`\`text
${route:-route unavailable}
\`\`\`

## Trace Summary

\`\`\`text
$(trace_summary "$route_target")
\`\`\`

## Mermaid Flow

\`\`\`mermaid
flowchart LR
  app["App / client\\n$input"]
  dns["DNS resolver\\n$(escape_mermaid "${dns:-unknown}")"]
  target_ip["Resolved target\\n$(escape_mermaid "${route_target:-unavailable}")"]
  route["Kernel route\\ndev $(escape_mermaid "${dev:-unknown}")\\nsrc $(escape_mermaid "${src:-unknown}")"]
  gateway["Gateway / next hop\\n$(escape_mermaid "${via:-direct or unknown}")"]
  egress["Observed public IP\\nIPv4 $(escape_mermaid "${pub4:-unavailable}")\\nIPv6 $(escape_mermaid "${pub6:-unavailable}")"]
  target["Target service\\n$(escape_mermaid "$host"):$port"]

  app --> dns
  dns --> target_ip
  app --> route
  route --> gateway
  gateway --> egress
  egress --> target
\`\`\`

## Notes

- This report is from the local machine's point of view.
- CDN, DNS load balancing, IPv6, browser DoH, and proxies can change the observed path.
- Do not publish reports containing real public IPs, private subnets, hostnames, or resolver details unless they are intentionally sanitized.
REPORT
