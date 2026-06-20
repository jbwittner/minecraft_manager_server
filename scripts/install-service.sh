#!/usr/bin/env bash
# Installe et active le service systemd 'minecraft' (démarrage auto au boot).
# Nécessite sudo. Génère l'unité avec les chemins/utilisateur résolus.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

if ! need screen; then
  log "Installation de screen (requis pour la console)…"
  sudo apt-get update -qq
  sudo apt-get install -y screen
fi

if [[ ! -x "$JAVA_BIN" ]]; then
  err "Java introuvable ($JAVA_BIN). Lance d'abord download-java.sh."
  exit 1
fi
if [[ ! -f "$SERVER_JAR" ]]; then
  err "server.jar introuvable. Lance d'abord download-server.sh."
  exit 1
fi

SCREEN_BIN="$(command -v screen)"

log "Écriture de l'unité systemd → $UNIT_PATH"
sudo tee "$UNIT_PATH" >/dev/null <<EOF
[Unit]
Description=Minecraft Vanilla Server
After=network.target

[Service]
Type=forking
User=${RUN_USER}
WorkingDirectory=${SERVER_DIR}
ExecStart=${SCREEN_BIN} -dmS ${SCREEN_NAME} ${JAVA_BIN} -Xms${JVM_XMS} -Xmx${JVM_XMX} -jar ${SERVER_JAR} nogui
ExecStop=${SCREEN_BIN} -p 0 -S ${SCREEN_NAME} -X eval 'stuff "say Arret du serveur dans 5s...\\n"' 'stuff "stop\\n"'
Restart=on-failure
RestartSec=10
TimeoutStopSec=90
SuccessExitStatus=0 1

[Install]
WantedBy=multi-user.target
EOF

log "Rechargement de systemd et activation au boot…"
sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"

log "Service installé. Démarre-le avec : scripts/start.sh"
