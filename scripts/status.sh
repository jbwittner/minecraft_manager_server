#!/usr/bin/env bash
# Affiche l'état du serveur Minecraft : service, version, uptime, RAM, port, joueurs.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

bold() { printf '\033[1m%s\033[0m' "$*"; }
green() { printf '\033[1;32m%s\033[0m' "$*"; }
red() { printf '\033[1;31m%s\033[0m' "$*"; }

PORT="$(grep -E '^server-port=' "$SERVER_DIR/server.properties" 2>/dev/null | cut -d= -f2 || true)"
PORT="${PORT:-25565}"

echo "===== État du serveur Minecraft ====="

# --- Version ---
if [[ -f "$SERVER_DIR/.version" ]]; then
  printf '%-14s %s\n' "Version" "$(cat "$SERVER_DIR/.version")"
else
  printf '%-14s %s\n' "Version" "inconnue (server.jar pas encore téléchargé ?)"
fi

# --- État systemd ---
active="$(systemctl is-active "$SERVICE_NAME" 2>/dev/null || true)"
enabled="$(systemctl is-enabled "$SERVICE_NAME" 2>/dev/null || true)"
if [[ "$active" == "active" ]]; then
  printf '%-14s %s\n' "Service" "$(green "● actif (running)")"
else
  printf '%-14s %s\n' "Service" "$(red "○ ${active:-non installé}")"
fi
printf '%-14s %s\n' "Au boot" "${enabled:-inconnu}"

# --- Processus Java : PID, uptime, RAM ---
pid="$(pgrep -f "$SERVER_JAR" 2>/dev/null | head -1 || true)"
if [[ -n "$pid" ]]; then
  uptime_h="$(ps -o etime= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
  rss_kb="$(ps -o rss= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
  printf '%-14s %s\n' "PID" "$pid"
  printf '%-14s %s\n' "Uptime" "${uptime_h:-?}"
  if [[ -n "${rss_kb:-}" ]]; then
    printf '%-14s %s\n' "RAM utilisée" "$(( rss_kb / 1024 )) Mo (max -Xmx${JVM_XMX})"
  fi
else
  printf '%-14s %s\n' "Processus" "$(red "aucun processus serveur")"
fi

# --- Port d'écoute ---
if command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q ":${PORT}\b"; then
  printf '%-14s %s\n' "Port $PORT" "$(green "en écoute")"
else
  printf '%-14s %s\n' "Port $PORT" "$(red "fermé")"
fi

# --- Joueurs connectés (via la console screen) ---
if [[ -n "$pid" ]] && sudo -u "$RUN_USER" screen -ls 2>/dev/null | grep -q "\.${SCREEN_NAME}\b"; then
  logfile="$SERVER_DIR/logs/latest.log"
  if [[ -r "$logfile" ]]; then
    before="$(wc -l < "$logfile")"
    sudo -u "$RUN_USER" screen -p 0 -S "$SCREEN_NAME" -X stuff "list$(printf '\r')" 2>/dev/null || true
    sleep 1
    line="$(tail -n +"$((before+1))" "$logfile" 2>/dev/null | grep -oE 'There are [0-9]+ of a max of [0-9]+ players online.*' | tail -1 || true)"
    [[ -n "$line" ]] && printf '%-14s %s\n' "Joueurs" "$line"
  fi
fi

echo "====================================="
echo "Logs en direct : journalctl -u $SERVICE_NAME -f"
