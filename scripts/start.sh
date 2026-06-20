#!/usr/bin/env bash
# Démarre le serveur (service systemd).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
sudo systemctl start "$SERVICE_NAME"
log "Serveur démarré. Logs : journalctl -u $SERVICE_NAME -f"
sudo systemctl --no-pager status "$SERVICE_NAME" || true
