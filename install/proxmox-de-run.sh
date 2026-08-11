#!/usr/bin/env bash
set -Eeuo pipefail
URL="https://raw.githubusercontent.com/Terranom674/Gitea-Connector/main/install/proxmox-de.sh"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
curl -fsSL "$URL" -o "$TMP"
sed -i 's/^  printf '\''%s \[%s\]: '\'' "$prompt" "$default"$/  printf '\''%s [%s]: '\'' "$prompt" "$default" >\&2/' "$TMP"
python3 - "$TMP" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = '''HOSTNAME="$(frage_standard 'Hostname' "$DEFAULT_HOSTNAME")"
[[ "$HOSTNAME" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]] || fehler "Ungültiger Hostname."'''
new = '''echo >&2
echo "Name des neuen LXC" >&2
echo "Dieser Name wird in Proxmox angezeigt und zugleich als Hostname verwendet." >&2
while true; do
  printf 'Gewünschter LXC-Name: ' > /dev/tty
  read -r HOSTNAME < /dev/tty
  [[ -n "$HOSTNAME" ]] || { echo "Der LXC-Name darf nicht leer sein." >&2; continue; }
  [[ "$HOSTNAME" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]] || { echo "Ungültiger Name. Erlaubt sind Buchstaben, Zahlen, Punkt und Bindestrich." >&2; continue; }
  break
done'''
if old not in s:
    raise SystemExit('Hostname block not found')
p.write_text(s.replace(old, new))
PY
exec bash "$TMP"
