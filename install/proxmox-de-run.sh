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
s = s.replace(old, new)
old = '''if [[ "$NET_MODE" == "static" ]]; then
  printf 'IPv4-Adresse mit CIDR (Beispiel 192.168.1.50/24): '
  read -r IP_CIDR
  [[ "$IP_CIDR" =~ ^[0-9]{1,3}(\\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]] || fehler "IPv4 bitte in CIDR-Schreibweise eingeben, z. B. 192.168.1.50/24."
  printf 'IPv4-Gateway (Beispiel 192.168.1.1): '
  read -r GATEWAY
  [[ "$GATEWAY" =~ ^[0-9]{1,3}(\\.[0-9]{1,3}){3}$ ]] || fehler "Ungültiges IPv4-Gateway."
fi
printf 'VLAN-ID [keine]: '
read -r VLAN_TAG
if [[ -n "$VLAN_TAG" ]]; then
  [[ "$VLAN_TAG" =~ ^[0-9]+$ ]] || fehler "Die VLAN-ID muss numerisch sein."
  (( VLAN_TAG >= 1 && VLAN_TAG <= 4094 )) || fehler "Die VLAN-ID muss zwischen 1 und 4094 liegen."
fi'''
new = '''if [[ "$NET_MODE" == "static" ]]; then
  while true; do
    printf 'IPv4-Adresse mit CIDR (Beispiel 192.168.1.50/24): ' > /dev/tty
    read -r IP_CIDR < /dev/tty
    if [[ "$IP_CIDR" =~ ^[0-9]{1,3}(\\.[0-9]{1,3}){3}/([0-9]|[12][0-9]|3[0-2])$ ]]; then
      break
    fi
    echo "Ungültige Eingabe. Bitte die Adresse inklusive Netzmaske angeben, z. B. 192.168.51.17/24." >&2
  done
  while true; do
    printf 'IPv4-Gateway (Beispiel 192.168.1.1): ' > /dev/tty
    read -r GATEWAY < /dev/tty
    if [[ "$GATEWAY" =~ ^[0-9]{1,3}(\\.[0-9]{1,3}){3}$ ]]; then
      break
    fi
    echo "Ungültiges IPv4-Gateway. Bitte erneut eingeben, z. B. 192.168.51.1." >&2
  done
fi
while true; do
  printf 'VLAN-ID [keine]: ' > /dev/tty
  read -r VLAN_TAG < /dev/tty
  [[ -z "$VLAN_TAG" ]] && break
  if [[ "$VLAN_TAG" =~ ^[0-9]+$ ]] && (( VLAN_TAG >= 1 && VLAN_TAG <= 4094 )); then
    break
  fi
  echo "Ungültige VLAN-ID. Erlaubt sind 1 bis 4094 oder Enter für keine VLAN-ID." >&2
done'''
if old not in s:
    raise SystemExit('Network input block not found')
s = s.replace(old, new)
p.write_text(s)
PY
exec bash "$TMP"
