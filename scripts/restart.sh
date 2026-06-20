#!/usr/bin/env bash
# Redémarre le serveur (service systemd).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
sudo systemctl restart "$SERVICE_NAME"
log "Serveur redémarré."
