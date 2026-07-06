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

- **RAM** : variables `JVM_XMS` (mémoire initiale) / `JVM_XMX` (mémoire max) dans [scripts/common.sh](scripts/common.sh) (défaut `1G` / `2G`). Éditer les valeurs, par exemple :
  ```bash
  JVM_XMS="2G"
  JVM_XMX="4G"
  ```
  Suffixes acceptés : `M` (Mo) ou `G` (Go) — ex. `512M`, `3G`. Après modif, relancer `scripts/install-service.sh` puis `scripts/restart.sh`.

  **Comment calculer** : `JVM_XMX` = RAM totale − réserve OS (~1 à 1,5 Go). Régler `JVM_XMS = JVM_XMX` (recommandé pour Minecraft : évite le redimensionnement du tas). RAM totale : `free -h` (colonne `total`).

  | RAM machine | XMS = XMX conseillé |
  |-------------|---------------------|
  | 2 Go        | `1G`                |
  | 4 Go        | `2G` à `3G`         |
  | 8 Go        | `6G`                |
  | 16 Go       | `12G` à `14G`       |

  Ne pas allouer toute la RAM : l'OS, `screen` et le cache disque en ont besoin. Trop d'`Xmx` → OOM killer tue le serveur.
- **Propriétés du serveur** : [server/server.properties](server/server.properties) (puis `scripts/restart.sh`).
- **Seed du monde** : à l'installation, passer la variable `MC_SEED` :
  ```bash
  MC_SEED=12345 scripts/install.sh
  ```
  La seed n'agit qu'à la **première génération** du monde. Pour la changer ensuite : éditer `level-seed` dans `server/server.properties` **et supprimer `server/world*`** (le monde n'est pas régénéré automatiquement), puis `scripts/restart.sh`.
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
