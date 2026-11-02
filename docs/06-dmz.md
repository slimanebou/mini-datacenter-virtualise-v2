# Phase 6 — DMZ (Web-20)

Objectif : héberger le seul service exposé dans une zone où il reste enfermé s'il est compromis. L'application lit réellement la base, ce qui prouve l'usage du flux 3306 (faille n°9 du TER).

## Configuration

Debian 13 (clone) — 2 Go RAM, 2 vCPU, une carte sur `LAN-20-DMZ`. Nom d'hôte `web`, IP 192.168.20.10/24, passerelle, DNS et NTP sur 192.168.20.1.

### Application

Nginx (reverse proxy) → Flask/Gunicorn → MariaDB sur db (192.168.60.10:3306, compte `app_web` en lecture seule).

| Mesure | Mise en œuvre |
|---|---|
| Sans root | App en `uid 10001`, Nginx en image `nginx-unprivileged` (port 8080, publié en 80) |
| Lecture seule | `read_only: true`, seul `/tmp` en écriture (tmpfs) |
| Sans capacités | `cap_drop: [ALL]`, `no-new-privileges` |
| Version masquée | `server_tokens off` |
| Secrets hors Git | Mot de passe SQL dans `.env` (chmod 600, exclu par `.gitignore`) |
| Image minimale | `pip`, `setuptools`, `wheel` et `ensurepip` retirés après installation |

Fichiers : `configs/web/web-app/` (sans `.env`).

### Règles pfSense (interface DMZ)

| # | Action | Proto | Source | Destination | Port | Rôle |
|---|---|---|---|---|---|---|
| 1 | Pass | TCP/UDP | DMZ subnets | DMZ address | 53 | DNS vers pfSense |
| 2 | Pass | UDP | DMZ subnets | DMZ address | 123 | NTP vers pfSense |
| 3 | Pass | TCP | 192.168.20.10 | 192.168.60.10 | 3306 | web → MariaDB |
| 4 | Pass | TCP | DMZ subnets | ! RFC1918 | PORTS_WEB | Mises à jour, docker pull |

Aucune règle vers SERVEURS, POSTES, INVITÉS ni vers la GUI de pfSense : tout est bloqué implicitement.

## Preuves

| Test | Résultat |
|---|---|
| `docker compose ps` | 2 conteneurs Up, `0.0.0.0:80->8080` |
| `docker compose exec app id` | `uid=10001(app)` |
| `curl localhost/health` | `{"db":"ok","status":"ok"}` |
| `curl -sI localhost` | `Server: nginx` (sans version) |
| DMZ → 192.168.10.10:445 / 192.168.40.100:445 / 192.168.20.1:443 | BLOQUE ×3 (faille n°3 du TER corrigée) |
| Trivy HIGH/CRITICAL corrigeables | Debian 0 ; Python 5 → 0 après retrait de pip |
| Page `http://192.168.20.10` depuis Admin-40 | Inventaire lu dans MariaDB |

![Page d'inventaire servie par la DMZ](img/06-web-inventaire.png)

Snapshot : `P06-web-ok`.

## Difficultés

- **Carte héritée du template en NAT** : le clone a obtenu une IP 192.168.204.x et contournait pfSense. Correction : carte sur `LAN-20-DMZ`. Leçon : vérifier systématiquement le segment après un clonage.
- **dhcpcd** : le client DHCP du template recréait une adresse 169.254 et effaçait la route par défaut, ce qui coupait le retour des paquets (le ping d'Admin-40 passait pfSense sans réponse). Diagnostic par élimination : ARP vers pfSense OK, aucun pare-feu local, aucun blocage dans les journaux pfSense, donc problème de route sur la VM. Solution : arrêter dhcpcd puis passer la carte en `static`. Cause racine traitée par la généralisation du template (phase 7).
- **`su` au lieu de `su -`** : l'environnement root incomplet (PATH sans `/usr/sbin`) rendait `dpkg-reconfigure` introuvable.
- **Règle des mises à jour** : `apt` résolvait les noms mais ne se connectait pas ; la règle 4 de la DMZ était mal saisie.
- **`/tmp` et sticky bit** : un fichier créé par root dans `/tmp` ne peut pas être écrasé par un autre utilisateur.
- **Trivy** : 5 vulnérabilités HIGH venaient de bibliothèques embarquées dans `pip` (msgpack, urllib3) et de setuptools, inutiles à l'exécution. Leur retrait ramène le scan à 0.
- **502 Bad Gateway** : Nginx résout le nom `app` une seule fois au démarrage. Après la recréation du conteneur app, il visait l'ancienne IP. Correction : redémarrer Nginx (ou utiliser `resolver 127.0.0.11`).