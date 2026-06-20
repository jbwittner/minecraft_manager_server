# Serveur Minecraft Vanilla

Serveur Minecraft Java **Vanilla** (dernière version stable), géré par des scripts et un service **systemd** (démarrage automatique au boot).

## Prérequis

- Ubuntu (testé sur 24.04), x86_64
- `sudo` (pour installer le service systemd et `screen`)
- Connexion Internet (téléchargement de Java + server.jar)

Java n'a **pas** besoin d'être installé : il est téléchargé localement dans `./jdk` (Eclipse Temurin 25, requis par les versions récentes de Minecraft).

## Installation

```bash
cd ~/minecraft
scripts/install.sh
```

Le script enchaîne : téléchargement de Java → téléchargement du `server.jar` → acceptation de l'[EULA](https://www.minecraft.net/eula) (demandée explicitement) → création de `server.properties` → installation + activation du service systemd.

## Gestion au quotidien

| Action | Commande |
|--------|----------|
| Démarrer | `scripts/start.sh` |
| Arrêter (sauvegarde le monde) | `scripts/stop.sh` |
| Redémarrer | `scripts/restart.sh` |
| État du serveur | `scripts/status.sh` |
| Console interactive | `scripts/console.sh` |
| Sauvegarde du monde | `scripts/backup.sh` |
| Logs en direct | `journalctl -u minecraft -f` |
| Statut | `systemctl status minecraft` |

### Console

`scripts/console.sh` s'attache à la session `screen` du serveur. Vous pouvez y taper des commandes Minecraft (`list`, `op <pseudo>`, `gamemode`, etc.).
**Pour quitter la console sans arrêter le serveur : `Ctrl-A` puis `D`.**

## Configuration

- **RAM** : variables `JVM_XMS` / `JVM_XMX` dans [scripts/common.sh](scripts/common.sh) (défaut `1G` / `2G`). Après modif, relancer `scripts/install-service.sh` puis `scripts/restart.sh`.
- **Propriétés du serveur** : [server/server.properties](server/server.properties) (puis `scripts/restart.sh`).
- **Mettre à jour le serveur** : `scripts/download-server.sh` puis `scripts/restart.sh`.

## Accès réseau

Le serveur écoute sur le port **25565/TCP**.

- **Réseau local** : les joueurs se connectent à `IP_LOCALE:25565`.
- **Depuis Internet** : ouvrir/rediriger le port `25565` sur votre box/routeur vers cette machine, et autoriser le port dans le pare-feu (`sudo ufw allow 25565/tcp` si `ufw` est actif).

## Démarrage automatique

Le service est activé (`systemctl enable minecraft`) : il démarre seul au boot et redémarre automatiquement en cas de crash.

## Structure

```
minecraft/
├── jdk/        Java 21 (Temurin), téléchargé
├── server/     données du serveur (world, server.properties, server.jar, logs)
├── backups/    archives du monde
└── scripts/    scripts de gestion
```
