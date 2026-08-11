#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="https://raw.githubusercontent.com/Terranom674/Gitea-Connector/main/install"

echo
echo "============================================================"
echo " Gitea MCP - Proxmox Installer"
echo "============================================================"
echo "Sprache wählen / Choose language:"
echo "  1) Deutsch"
echo "  2) English"
printf 'Auswahl / Selection [1]: '
read -r LANGUAGE
LANGUAGE="${LANGUAGE:-1}"

case "$LANGUAGE" in
  1|de|DE|Deutsch|deutsch)
    SCRIPT="proxmox-de-run.sh"
    ;;
  2|en|EN|English|english)
    SCRIPT="proxmox-en-run.sh"
    ;;
  *)
    echo "Ungültige Auswahl / Invalid selection." >&2
    exit 1
    ;;
esac

exec bash <(curl -fsSL "$BASE_URL/$SCRIPT")
