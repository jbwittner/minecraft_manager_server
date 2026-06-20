#!/usr/bin/env bash
# Télécharge le dernier server.jar Vanilla stable depuis l'API officielle Mojang.
# Vérifie le SHA1 fourni par le manifeste.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

MANIFEST="https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"

for dep in curl jq; do
  if ! need "$dep"; then
    err "$dep est requis. Installe-le : sudo apt install -y $dep"
    exit 1
  fi
done

log "Résolution de la dernière version stable…"
latest="$(curl -fsSL "$MANIFEST" | jq -r '.latest.release')"
version_url="$(curl -fsSL "$MANIFEST" | jq -r --arg v "$latest" '.versions[] | select(.id==$v) | .url')"

if [[ -z "$version_url" || "$version_url" == "null" ]]; then
  err "Impossible de résoudre l'URL de la version $latest."
  exit 1
fi

meta="$(curl -fsSL "$version_url")"
server_url="$(echo "$meta" | jq -r '.downloads.server.url')"
server_sha1="$(echo "$meta" | jq -r '.downloads.server.sha1')"

if [[ -z "$server_url" || "$server_url" == "null" ]]; then
  err "Cette version ($latest) ne fournit pas de server.jar."
  exit 1
fi

log "Version $latest → téléchargement du server.jar…"
mkdir -p "$SERVER_DIR"
curl -fSL --retry 3 -o "$SERVER_JAR" "$server_url"

log "Vérification SHA1…"
got="$(sha1sum "$SERVER_JAR" | awk '{print $1}')"
if [[ "$got" != "$server_sha1" ]]; then
  err "SHA1 invalide ! attendu=$server_sha1 obtenu=$got"
  rm -f "$SERVER_JAR"
  exit 1
fi

echo "$latest" > "$SERVER_DIR/.version"
log "server.jar Minecraft $latest installé et vérifié."
