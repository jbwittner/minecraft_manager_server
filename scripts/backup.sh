#!/usr/bin/env bash
# Sauvegarde le monde dans backups/world-DATE.tar.gz.
# Si le serveur tourne, désactive temporairement l'auto-save pour une archive cohérente.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

mkdir -p "$BACKUP_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="$BACKUP_DIR/world-$STAMP.tar.gz"

running=0
if sudo -u "$RUN_USER" screen -ls 2>/dev/null | grep -q "\.${SCREEN_NAME}\b"; then
  running=1
fi

mc_cmd() {
  sudo -u "$RUN_USER" screen -p 0 -S "$SCREEN_NAME" -X stuff "$1$(printf '\r')"
}

if [[ "$running" -eq 1 ]]; then
  log "Serveur actif → save-off / save-all avant archivage."
  mc_cmd "save-off"
  mc_cmd "save-all flush"
  sleep 3
fi

# Archive tous les mondes (world, world_nether, world_the_end le cas échéant)
shopt -s nullglob
worlds=("$SERVER_DIR"/world*)
if [[ ${#worlds[@]} -eq 0 ]]; then
  warn "Aucun dossier 'world*' trouvé dans $SERVER_DIR (monde pas encore généré ?)."
else
  log "Archivage → $ARCHIVE"
  tar -czf "$ARCHIVE" -C "$SERVER_DIR" "${worlds[@]##*/}"
fi

if [[ "$running" -eq 1 ]]; then
  mc_cmd "save-on"
  log "save-on réactivé."
fi

[[ -f "$ARCHIVE" ]] && log "Sauvegarde terminée : $ARCHIVE"
