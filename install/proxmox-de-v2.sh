#!/usr/bin/env bash
set -Eeuo pipefail

# Temporary compatibility wrapper around the current advanced installer.
# It patches the prompt helper before execution so prompts and reads use /dev/tty
# instead of being swallowed by command substitution.
BASE_URL="https://raw.githubusercontent.com/Terranom674/Gitea-Connector/main/install"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

curl -fsSL "$BASE_URL/proxmox-de.sh" -o "$TMP"

python3 - "$TMP" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = '''frage_standard() {
  local prompt="$1" default="$2" value
  printf '%s [%s]: ' "$prompt" "$default"
  read -r value
  printf '%s' "${value:-$default}"
}'''
new = '''frage_standard() {
  local prompt="$1" default="$2" value
  printf '%s [%s]: ' "$prompt" "$default" > /dev/tty
  IFS= read -r value < /dev/tty
  printf '%s' "${value:-$default}"
}'''
if old not in s:
    raise SystemExit('Interner Installerfehler: Eingabefunktion konnte nicht aktualisiert werden.')
s = s.replace(old, new, 1)
marker = 'NEXT_ID="$(pvesh get /cluster/nextid 2>/dev/null || true)"'
intro = '''echo "------------------------------------------------------------"
echo " 1. LXC-Grundeinstellungen"
echo "------------------------------------------------------------"
echo "Im folgenden Abschnitt legst du fest, wie der neue LXC in"
echo "Proxmox angelegt wird. Werte in [eckigen Klammern] sind"
echo "Vorschlaege. Mit Enter uebernimmst du den jeweiligen Wert."
echo
'''
s = s.replace(marker, intro + marker, 1)
marker2 = 'printf \'Netzwerkmodus [statisch/dhcp] [statisch]: \'\n'
intro2 = '''echo
echo "------------------------------------------------------------"
echo " 2. Netzwerk"
echo "------------------------------------------------------------"
echo "Fuer einen dauerhaft laufenden MCP ist eine statische IP"
echo "empfohlen. DHCP ist ebenfalls moeglich."
echo
'''
s = s.replace(marker2, intro2 + marker2, 1)
marker3 = 'printf \'Gitea-Basis-URL (Beispiel https://git.example.com): \'\n'
intro3 = '''echo
echo "------------------------------------------------------------"
echo " 3. Gitea-Verbindung"
echo "------------------------------------------------------------"
echo "Jetzt werden die Zugangsdaten deiner Gitea-Instanz benoetigt."
echo "Der Token wird bei der Eingabe nicht angezeigt."
echo
'''
s = s.replace(marker3, intro3 + marker3, 1)
marker4 = 'printf \'OpenAI Secure MCP Tunnel-ID (tunnel_...): \'\n'
intro4 = '''echo
echo "------------------------------------------------------------"
echo " 4. OpenAI Secure MCP Tunnel"
echo "------------------------------------------------------------"
echo "Diese Daten verbinden den privaten MCP spaeter mit ChatGPT."
echo "Der Runtime API-Key wird bei der Eingabe nicht angezeigt."
echo
'''
s = s.replace(marker4, intro4 + marker4, 1)
p.write_text(s)
PY

exec bash "$TMP"
