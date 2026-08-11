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
    SCRIPT="proxmox-de-v2.sh"
    echo
    echo "============================================================"
    echo " Vorbereitung"
    echo "============================================================"
    echo "Für die vollständige Installation benötigst du später:"
    echo
    echo "1. Gitea-Basis-URL"
    echo "2. Gitea-Zugriffstoken"
    echo "3. OpenAI Secure MCP Tunnel-ID"
    echo "4. OpenAI Tunnel Runtime API-Key"
    echo
    echo "WICHTIG: Tunnel-ID und Runtime API-Key werden nicht vom"
    echo "Installer erzeugt. Sie müssen vorher in der OpenAI Platform"
    echo "für einen Secure MCP Tunnel angelegt werden."
    echo
    echo "Die OpenAI-Dokumentation bestätigt, dass ein privater/lokaler"
    echo "MCP über Secure MCP Tunnel mit ChatGPT verbunden werden kann."
    echo
    echo "Halte Tunnel-ID und Runtime API-Key bereit, bevor du Abschnitt 4"
    echo "des Installers erreichst. Der Runtime API-Key wird bei der"
    echo "Eingabe nicht angezeigt."
    echo
    echo "Ausführliche Vorbereitung: README.md / Installationshandbuch"
    echo
    ;;
  2|en|EN|English|english)
    SCRIPT="proxmox-en-v2.sh"
    echo
    echo "============================================================"
    echo " Preparation"
    echo "============================================================"
    echo "For the complete installation you will need:"
    echo
    echo "1. Gitea base URL"
    echo "2. Gitea access token"
    echo "3. OpenAI Secure MCP Tunnel ID"
    echo "4. OpenAI Tunnel Runtime API key"
    echo
    echo "IMPORTANT: The tunnel ID and runtime API key are not generated"
    echo "by this installer. They must be created beforehand in the"
    echo "OpenAI Platform for a Secure MCP Tunnel."
    echo
    echo "OpenAI documentation confirms that a private/local MCP can be"
    echo "connected to ChatGPT using Secure MCP Tunnel."
    echo
    echo "Have the tunnel ID and runtime API key ready before section 4."
    echo "The runtime API key is hidden while you enter it."
    echo
    echo "Detailed preparation: README.md / installation guide"
    echo
    ;;
  *)
    echo "Ungültige Auswahl / Invalid selection." >&2
    exit 1
    ;;
esac

exec bash <(curl -fsSL "$BASE_URL/$SCRIPT")