#!/usr/bin/env bash
# État du serveur Minecraft. Par défaut : tableau de bord qui se rafraîchit
# (RAM/CPU machine + Minecraft). Ctrl-C pour quitter.
#   status.sh          # rafraîchit toutes les 2 s
#   status.sh 5        # rafraîchit toutes les 5 s
#   status.sh --once   # affichage unique (inclut la liste des joueurs)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

green() { printf '\033[1;32m%s\033[0m' "$*"; }
red()   { printf '\033[1;31m%s\033[0m' "$*"; }

ONCE=0
INTERVAL=2
for arg in "$@"; do
  case "$arg" in
    --once|-1) ONCE=1 ;;
    *) [[ "$arg" =~ ^[0-9]+$ ]] && INTERVAL="$arg" ;;
  esac
done

NCPU="$(nproc 2>/dev/null || echo 1)"

# kB -> Mo / Go lisible
human_kb() {
  awk -v k="$1" 'BEGIN{ if (k>=1048576) printf "%.1f Go", k/1048576; else printf "%d Mo", k/1024 }'
}

# Échantillon CPU global : "total idle" en jiffies (ligne 'cpu ' de /proc/stat)
cpu_sample() { awk '/^cpu /{t=0; for(i=2;i<=NF;i++) t+=$i; print t, $5+$6}' /proc/stat; }

# Jiffies CPU d'un process : utime+stime (champs 14+15 de /proc/<pid>/stat)
pid_jiffies() { awk '{print $14+$15}' "/proc/$1/stat" 2>/dev/null || echo 0; }

# Affiche une frame. Args : cpu_machine% cpu_minecraft% pid
render() {
  local mach_cpu="$1" mc_cpu="$2" pid="$3"
  clear
  echo "===== État du serveur Minecraft ====="

  if [[ -f "$SERVER_DIR/.version" ]]; then
    printf '%-16s %s\n' "Version" "$(cat "$SERVER_DIR/.version")"
  else
    printf '%-16s %s\n' "Version" "inconnue (server.jar pas téléchargé ?)"
  fi

  local active enabled
  active="$(systemctl is-active "$SERVICE_NAME" 2>/dev/null || true)"
  enabled="$(systemctl is-enabled "$SERVICE_NAME" 2>/dev/null || true)"
  if [[ "$active" == "active" ]]; then
    printf '%-16s %s\n' "Service" "$(green "● actif (running)")"
  else
    printf '%-16s %s\n' "Service" "$(red "○ ${active:-non installé}")"
  fi
  printf '%-16s %s\n' "Au boot" "${enabled:-inconnu}"

  if [[ -n "$pid" ]]; then
    local uptime
    uptime="$(ps -o etime= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
    printf '%-16s %s\n' "PID" "$pid"
    printf '%-16s %s\n' "Uptime" "${uptime:-?}"
  else
    printf '%-16s %s\n' "Processus" "$(red "aucun processus serveur")"
  fi

  # --- Mémoire ---
  echo "----- Mémoire -----"
  local memtotal memavail memused
  memtotal="$(awk '/^MemTotal:/{print $2}' /proc/meminfo)"
  memavail="$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)"
  memused=$((memtotal - memavail))
  printf '%-16s %s\n' "RAM max" "$(human_kb "$memtotal")"
  printf '%-16s %s (%d%%)\n' "RAM machine" "$(human_kb "$memused")" $((memused * 100 / memtotal))
  if [[ -n "$pid" ]]; then
    local rss
    rss="$(ps -o rss= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
    if [[ -n "${rss:-}" ]]; then
      printf '%-16s %s (%d%% machine / max -Xmx%s)\n' \
        "RAM Minecraft" "$(human_kb "$rss")" $((rss * 100 / memtotal)) "$JVM_XMX"
    fi
  fi

  # --- CPU (en % de la machine entière, tous cœurs) ---
  echo "----- CPU ($NCPU cœurs) -----"
  printf '%-16s %s%%\n' "CPU machine" "$mach_cpu"
  [[ -n "$pid" ]] && printf '%-16s %s%%\n' "CPU Minecraft" "$mc_cpu"

  # --- Port d'écoute ---
  local PORT
  PORT="$(grep -E '^server-port=' "$SERVER_DIR/server.properties" 2>/dev/null | cut -d= -f2 || true)"
  PORT="${PORT:-25565}"
  if command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q ":${PORT}\b"; then
    printf '%-16s %s\n' "Port $PORT" "$(green "en écoute")"
  else
    printf '%-16s %s\n' "Port $PORT" "$(red "fermé")"
  fi
}

# Échantillonne le CPU sur une courte fenêtre puis affiche une frame.
sample_and_render() {
  local pid t1 i1 t2 i2 pj1 pj2 dt mach mc
  pid="$(pgrep -f "$SERVER_JAR" 2>/dev/null | head -1 || true)"

  read -r t1 i1 < <(cpu_sample)
  [[ -n "$pid" ]] && pj1="$(pid_jiffies "$pid")" || pj1=0
  sleep 0.4
  read -r t2 i2 < <(cpu_sample)
  [[ -n "$pid" ]] && pj2="$(pid_jiffies "$pid")" || pj2=0

  dt=$((t2 - t1)); [[ $dt -le 0 ]] && dt=1
  mach=$(( (dt - (i2 - i1)) * 100 / dt ))   # busy / total
  mc=$(( (pj2 - pj1) * 100 / dt ))          # process / total (% machine)

  render "$mach" "$mc" "$pid"
}

# Liste des joueurs (interroge la console screen — évitée en boucle pour ne pas spammer les logs).
show_players() {
  local pid logfile before line
  pid="$(pgrep -f "$SERVER_JAR" 2>/dev/null | head -1 || true)"
  [[ -z "$pid" ]] && return
  sudo -u "$RUN_USER" screen -ls 2>/dev/null | grep -q "\.${SCREEN_NAME}\b" || return
  logfile="$SERVER_DIR/logs/latest.log"
  [[ -r "$logfile" ]] || return
  before="$(wc -l < "$logfile")"
  sudo -u "$RUN_USER" screen -p 0 -S "$SCREEN_NAME" -X stuff "list$(printf '\r')" 2>/dev/null || true
  sleep 1
  line="$(tail -n +"$((before + 1))" "$logfile" 2>/dev/null | grep -oE 'There are [0-9]+ of a max of [0-9]+ players online.*' | tail -1 || true)"
  [[ -n "$line" ]] && printf '%-16s %s\n' "Joueurs" "$line"
}

if [[ "$ONCE" == 1 ]]; then
  sample_and_render
  show_players
  echo "====================================="
  echo "Logs en direct : journalctl -u $SERVICE_NAME -f"
else
  trap 'tput cnorm 2>/dev/null; echo; exit 0' INT TERM
  tput civis 2>/dev/null || true
  while true; do
    sample_and_render
    printf '\n(rafraîchi toutes les %s s — Ctrl-C pour quitter, --once pour un affichage figé)\n' "$INTERVAL"
    sleep "$INTERVAL"
  done
fi
