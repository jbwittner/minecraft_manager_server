#!/usr/bin/env bash
# Variables et fonctions communes à tous les scripts.
set -euo pipefail

# Racine du projet (dossier parent de scripts/)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

JDK_DIR="$ROOT_DIR/jdk"
SERVER_DIR="$ROOT_DIR/server"
BACKUP_DIR="$ROOT_DIR/backups"
SCRIPTS_DIR="$ROOT_DIR/scripts"

JAVA_BIN="$JDK_DIR/bin/java"
SERVER_JAR="$SERVER_DIR/server.jar"

# Nom du service systemd et de la session screen
SERVICE_NAME="minecraft"
SCREEN_NAME="minecraft"

# Mémoire allouée à la JVM (adapté à ~3.8 Go de RAM)
JVM_XMS="1G"
JVM_XMX="2G"

# Utilisateur qui possède/exécute le serveur
RUN_USER="$(id -un)"

log()  { printf '\033[1;32m[mc]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[mc]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[mc]\033[0m %s\n' "$*" >&2; }

need() {
  command -v "$1" >/dev/null 2>&1
}
