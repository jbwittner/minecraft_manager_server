#!/usr/bin/env bash
# Télécharge Eclipse Temurin JRE 21 (Linux x64) dans ./jdk, sans sudo.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

API="https://api.adoptium.net/v3/binary/latest/21/ga/linux/x64/jre/hotspot/normal/eclipse"

if [[ -x "$JAVA_BIN" ]]; then
  log "Java déjà présent : $("$JAVA_BIN" -version 2>&1 | head -1)"
  exit 0
fi

if ! need curl; then
  err "curl est requis. Installe-le : sudo apt install -y curl"
  exit 1
fi

TMP_TAR="$(mktemp --suffix=.tar.gz)"
trap 'rm -f "$TMP_TAR"' EXIT

log "Téléchargement de Temurin JRE 21 (Linux x64)…"
curl -fSL --retry 3 -o "$TMP_TAR" "$API"

log "Extraction dans $JDK_DIR…"
rm -rf "$JDK_DIR"
mkdir -p "$JDK_DIR"
# L'archive contient un dossier racine (jdk-21.x+...-jre). On l'aplatit dans ./jdk.
tar -xzf "$TMP_TAR" -C "$JDK_DIR" --strip-components=1

if [[ ! -x "$JAVA_BIN" ]]; then
  err "Échec : $JAVA_BIN introuvable après extraction."
  exit 1
fi

log "Java installé : $("$JAVA_BIN" -version 2>&1 | head -1)"
