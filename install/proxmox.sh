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

printf 'Optional MCP HTTP bearer token (leave empty to generate one): '
read -r -s MCP_HTTP_TOKEN
echo
if [[ -z "$MCP_HTTP_TOKEN" ]]; then
  MCP_HTTP_TOKEN="$(openssl rand -hex 24 2>/dev/null || head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 48)"
fi

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

pct exec "$CTID" -- bash -lc 'apt-get update >/dev/null && apt-get install -y git ca-certificates >/dev/null'
pct exec "$CTID" -- bash -lc "rm -rf /opt/gitea-connector && git clone --depth 1 '$REPO_URL' /opt/gitea-connector"

# Write secrets through stdin so they do not appear in the pct command line.
printf 'GITEA_URL=%s\nGITEA_TOKEN=%s\nMCP_HTTP_TOKEN=%s\nMCP_PORT=8000\nMCP_ALLOWED_ORIGINS=\n' \
  "$GITEA_URL" "$GITEA_TOKEN" "$MCP_HTTP_TOKEN" |
  pct exec "$CTID" -- bash -lc "umask 077; cat > '$APP_DIR/.env'"

pct exec "$CTID" -- bash -lc "cd '$APP_DIR' && docker compose up -d --build"

IP="$(pct exec "$CTID" -- hostname -I 2>/dev/null | awk '{print $1}')"

echo
echo "Gitea MCP installation completed."
echo "LXC ID: $CTID"
echo "LXC IP: ${IP:-unknown}"
echo "MCP endpoint inside the LXC: http://127.0.0.1:8000/mcp"
echo "Health check inside the LXC: http://127.0.0.1:8000/health"
echo
echo "MCP HTTP bearer token:"
echo "$MCP_HTTP_TOKEN"
echo
echo "Save that token now. The next step is connecting this private MCP to ChatGPT through the OpenAI Secure MCP Tunnel."
