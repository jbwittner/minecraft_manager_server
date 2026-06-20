#!/usr/bin/env bash
# Orchestration complète de l'installation du serveur Minecraft.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 1. Dépendances curl/jq
missing=()
for dep in curl jq; do need "$dep" || missing+=("$dep"); done
if [[ ${#missing[@]} -gt 0 ]]; then
  log "Installation des dépendances : ${missing[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y "${missing[@]}"
fi

# 2. Java
log "== Étape 1/5 : Java =="
bash "$SCRIPTS_DIR/download-java.sh"

# 3. server.jar
log "== Étape 2/5 : server.jar =="
bash "$SCRIPTS_DIR/download-server.sh"

# 4. EULA
log "== Étape 3/5 : EULA Minecraft =="
if [[ ! -f "$SERVER_DIR/eula.txt" ]] || ! grep -q '^eula=true' "$SERVER_DIR/eula.txt"; then
  echo "Vous devez accepter le CLUF Minecraft : https://www.minecraft.net/eula"
  read -r -p "Acceptez-vous l'EULA ? (oui/non) " ans
  case "${ans,,}" in
    oui|o|yes|y)
      printf '# Accepté via install.sh\neula=true\n' > "$SERVER_DIR/eula.txt"
      log "EULA accepté."
      ;;
    *)
      err "EULA non accepté → installation interrompue. Le serveur ne peut pas démarrer."
      exit 1
      ;;
  esac
else
  log "EULA déjà accepté."
fi

# 5. server.properties (uniquement si absent, pour ne pas écraser une config existante)
log "== Étape 4/5 : server.properties =="
if [[ ! -f "$SERVER_DIR/server.properties" ]]; then
  cat > "$SERVER_DIR/server.properties" <<'EOF'
# Config de départ — adaptée à ~3.8 Go de RAM. Modifiable librement.
motd=Serveur Minecraft Vanilla
max-players=5
view-distance=8
simulation-distance=6
online-mode=true
white-list=false
difficulty=normal
gamemode=survival
server-port=25565
spawn-protection=16
enable-command-block=false
EOF
  log "server.properties créé."
else
  log "server.properties existant conservé."
fi

# 6. Service systemd
log "== Étape 5/5 : Service systemd =="
bash "$SCRIPTS_DIR/install-service.sh"

log "Installation terminée ! Démarrer : scripts/start.sh"
