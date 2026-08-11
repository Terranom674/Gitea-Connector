#!/usr/bin/env bash
set -Eeuo pipefail
URL="https://raw.githubusercontent.com/Terranom674/Gitea-Connector/main/install/proxmox-en.sh"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
curl -fsSL "$URL" -o "$TMP"
sed -i 's/^  printf '\''%s \[%s\]: '\'' "$prompt" "$default"$/  printf '\''%s [%s]: '\'' "$prompt" "$default" >\&2/' "$TMP"
exec bash "$TMP"
