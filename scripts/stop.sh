#!/usr/bin/env bash
# Arrête proprement le serveur (service systemd → commande "stop").
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
sudo systemctl stop "$SERVICE_NAME"
log "Serveur arrêté (monde sauvegardé)."
