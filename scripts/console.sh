#!/usr/bin/env bash
# S'attache à la console du serveur (session screen).
# Taper des commandes Minecraft (ex: list, op <pseudo>, stop).
# Détacher sans arrêter le serveur : Ctrl-A puis D.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if ! sudo -u "$RUN_USER" screen -ls 2>/dev/null | grep -q "\.${SCREEN_NAME}\b"; then
  err "Aucune session screen '$SCREEN_NAME'. Le serveur tourne-t-il ? (scripts/start.sh)"
  exit 1
fi

log "Attache à la console. Détacher : Ctrl-A puis D."
sudo -u "$RUN_USER" screen -r "$SCREEN_NAME"
