#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/Terranom674/Gitea-Connector.git"
APP_DIR="/opt/gitea-connector/plugins/gitea-connector"
DOCKER_HELPER_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/docker.sh"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "This installer must be run as root on the Proxmox host." >&2
  exit 1
fi

if ! command -v pct >/dev/null 2>&1 || ! command -v pveversion >/dev/null 2>&1; then
  echo "This installer must be run in the shell of a Proxmox VE host." >&2
  exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "curl is required." >&2; exit 1; }

before_ids="$(pct list 2>/dev/null | awk 'NR>1 {print $1}' | sort -n || true)"

echo
echo "Gitea MCP - Proxmox installation"
echo "The installer will create a new Docker LXC, start the Gitea MCP and configure OpenAI Secure MCP Tunnel."
echo

printf 'Gitea base URL (example: https://git.example.com): '
read -r GITEA_URL
GITEA_URL="${GITEA_URL%/}"
if [[ ! "$GITEA_URL" =~ ^https?://[^[:space:]]+$ ]]; then
  echo "Invalid Gitea URL." >&2
  exit 1
fi

printf 'Gitea access token: '
read -r -s GITEA_TOKEN
echo
if [[ -z "$GITEA_TOKEN" ]]; then
  echo "A Gitea access token is required." >&2
  exit 1
fi

printf 'OpenAI Secure MCP Tunnel ID (tunnel_...): '
read -r OPENAI_TUNNEL_ID
if [[ ! "$OPENAI_TUNNEL_ID" =~ ^tunnel_[0-9a-f]{32}$ ]]; then
  echo "Invalid OpenAI tunnel ID." >&2
  exit 1
fi

printf 'OpenAI tunnel runtime API key: '
read -r -s OPENAI_TUNNEL_API_KEY
echo
if [[ -z "$OPENAI_TUNNEL_API_KEY" ]]; then
  echo "An OpenAI tunnel runtime API key is required." >&2
  exit 1
fi

# A local bearer token protects the MCP endpoint even inside the LXC.
MCP_HTTP_TOKEN="$(openssl rand -hex 24 2>/dev/null || head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 48)"

echo
echo "Creating a Docker LXC using the Proxmox VE Community Scripts helper..."
bash -c "$(curl -fsSL "$DOCKER_HELPER_URL")"

after_ids="$(pct list 2>/dev/null | awk 'NR>1 {print $1}' | sort -n || true)"
new_ids="$(comm -13 <(printf '%s\n' "$before_ids" | sed '/^$/d') <(printf '%s\n' "$after_ids" | sed '/^$/d') || true)"

if [[ $(printf '%s\n' "$new_ids" | sed '/^$/d' | wc -l) -ne 1 ]]; then
  echo "Could not uniquely determine the newly created LXC." >&2
  echo "New container IDs detected: ${new_ids:-none}" >&2
  echo "The Docker LXC itself may still have been created successfully." >&2
  exit 1
fi

CTID="$(printf '%s\n' "$new_ids" | sed '/^$/d' | head -n1)"
echo "Using new LXC: $CTID"

pct exec "$CTID" -- bash -lc 'apt-get update >/dev/null && apt-get install -y git ca-certificates curl unzip python3 >/dev/null'
pct exec "$CTID" -- bash -lc "rm -rf /opt/gitea-connector && git clone --depth 1 '$REPO_URL' /opt/gitea-connector"

# Write MCP secrets through stdin so they do not appear in the pct command line.
printf 'GITEA_URL=%s\nGITEA_TOKEN=%s\nMCP_HTTP_TOKEN=%s\nMCP_PORT=8000\nMCP_ALLOWED_ORIGINS=\n' \
  "$GITEA_URL" "$GITEA_TOKEN" "$MCP_HTTP_TOKEN" |
  pct exec "$CTID" -- bash -lc "umask 077; cat > '$APP_DIR/.env'"

pct exec "$CTID" -- bash -lc "cd '$APP_DIR' && docker compose up -d --build"

# Install the latest stable official OpenAI tunnel-client release for the LXC architecture.
pct exec "$CTID" -- bash -lc '
set -Eeuo pipefail
case "$(uname -m)" in
  x86_64) tunnel_arch="linux-amd64" ;;
  aarch64|arm64) tunnel_arch="linux-arm64" ;;
  *) echo "Unsupported architecture for OpenAI tunnel-client: $(uname -m)" >&2; exit 1 ;;
esac
release_json="$(curl -fsSL https://api.github.com/repos/openai/tunnel-client/releases/latest)"
download_url="$(printf "%s" "$release_json" | python3 -c "import json,sys; d=json.load(sys.stdin); arch=sys.argv[1]; urls=[a.get(\"browser_download_url\",\"\") for a in d.get(\"assets\",[]) if arch in a.get(\"name\",\"\") and a.get(\"name\",\"\").endswith(\".zip\")]; print(urls[0] if urls else \"\")" "$tunnel_arch")"
if [[ -z "$download_url" ]]; then
  echo "Could not find a tunnel-client release for $tunnel_arch." >&2
  exit 1
fi
rm -rf /tmp/openai-tunnel-client
mkdir -p /tmp/openai-tunnel-client
curl -fsSL "$download_url" -o /tmp/openai-tunnel-client/tunnel.zip
unzip -q /tmp/openai-tunnel-client/tunnel.zip -d /tmp/openai-tunnel-client
binary="$(find /tmp/openai-tunnel-client -type f -name tunnel-client | head -n1)"
if [[ -z "$binary" ]]; then
  echo "The tunnel-client binary was not found in the release archive." >&2
  exit 1
fi
install -m 0755 "$binary" /usr/local/bin/tunnel-client
rm -rf /tmp/openai-tunnel-client
'

# Store tunnel credentials only inside the LXC with root-only permissions.
printf 'CONTROL_PLANE_TUNNEL_ID=%s\nCONTROL_PLANE_API_KEY=%s\nMCP_SERVER_URL=http://127.0.0.1:8000/mcp\nMCP_EXTRA_HEADERS="Authorization: Bearer %s"\nMCP_DISCOVERY_EXTRA_HEADERS="Authorization: Bearer %s"\nHEALTH_LISTEN_ADDR=127.0.0.1:8080\nLOG_LEVEL=info\nLOG_FORMAT=struct-text\n' \
  "$OPENAI_TUNNEL_ID" "$OPENAI_TUNNEL_API_KEY" "$MCP_HTTP_TOKEN" "$MCP_HTTP_TOKEN" |
  pct exec "$CTID" -- bash -lc 'umask 077; cat > /etc/gitea-mcp-tunnel.env'

pct exec "$CTID" -- bash -lc 'cat > /etc/systemd/system/gitea-mcp-tunnel.service <<"EOF"
[Unit]
Description=OpenAI Secure MCP Tunnel for Gitea MCP
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=simple
EnvironmentFile=/etc/gitea-mcp-tunnel.env
ExecStart=/usr/local/bin/tunnel-client run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now gitea-mcp-tunnel.service
'

# Verify the MCP and a successful tunnel control-plane poll before handoff.
pct exec "$CTID" -- bash -lc 'for i in {1..30}; do curl -fsS http://127.0.0.1:8000/health >/dev/null && exit 0; sleep 2; done; echo "Gitea MCP health check failed." >&2; exit 1'
pct exec "$CTID" -- bash -lc 'for i in {1..30}; do curl -fsS http://127.0.0.1:8080/readyz >/dev/null && exit 0; sleep 2; done; systemctl --no-pager --full status gitea-mcp-tunnel.service || true; echo "OpenAI tunnel-client did not become ready." >&2; exit 1'

IP="$(pct exec "$CTID" -- hostname -I 2>/dev/null | awk '{print $1}')"

echo
echo "Gitea MCP installation completed."
echo "LXC ID: $CTID"
echo "LXC IP: ${IP:-unknown}"
echo "Gitea MCP: running"
echo "OpenAI Secure MCP Tunnel: connected and ready"
echo "Tunnel ID: $OPENAI_TUNNEL_ID"
echo
echo "The LXC is now intended to run unattended."
echo "The next step is only to select/connect tunnel $OPENAI_TUNNEL_ID when creating the Gitea MCP app in ChatGPT."
