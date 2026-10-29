# Mini Datacenter Virtualisé — v2

Refonte du projet TER de Master 1 (UVSQ) : un mini datacenter de 7 VMs découpé en 6 zones de confiance derrière pfSense, en filtrage stateful « default deny ». L'administration passe uniquement par un bastion Guacamole.

> Projet en cours de construction. Ce README sera complété avec les résultats réels à la fin du projet.

## Pourquoi une v2

La v1 (TER) présentait plusieurs faiblesses identifiées après publication, dont une remarque d'un CTO sur le mouvement latéral :

- postes d'administration dans la même zone que les serveurs ;
- base de données dans la zone d'administration, joignable depuis la DMZ ;
- DMZ et invités capables d'atteindre l'interface de pfSense et d'autres zones ;
- snapshots utilisés comme seules sauvegardes, sans test de restauration.

La v2 corrige ces points et prouve chaque flux par une matrice de tests.

## Architecture (cible)

| Zone | Réseau | VM (nom VMware) | IP |
|---|---|---|---|
| Serveurs (10) | 192.168.10.0/24 | `Dc-10` — Windows Server 2022 (AD DS, DNS, DHCP, NTP) | 192.168.10.10 |
| DMZ (20) | 192.168.20.0/24 | `Web-20` — Debian 13, Docker (Nginx + app) | 192.168.20.10 |
| Invités (30) | 192.168.30.0/24 | `Guest-30` — Debian 13 graphique | 192.168.30.10 |
| Postes admin (40) | 192.168.40.0/24 | `Admin-40` — Windows 11 | DHCP (relais) |
| Bastion (50) | 192.168.50.0/24 | `Bastion-50` — Debian 13, Guacamole | 192.168.50.10 |
| Données (60) | 192.168.60.0/24 | `Db-60` — Debian 13, MariaDB | 192.168.60.10 |
| Toutes | WAN + 6 réseaux | `pfSense-gw` — pfSense | `.1` partout |

Schéma interactif et suivi des phases : [`docs/schema/schema-suivi.html`](docs/schema/schema-suivi.html)

## Avancement

| Phase | Sujet | État |
|---|---|---|
| 0 | Préparation | ✅ |
| 1 | Réseaux VMware | ✅ |
| 2 | pfSense | 🔄 |
| 3 | Serveurs (10) | ⬜ |
| 4 | Postes admin (40) | ⬜ |
| 5 | DATA (60) | ⬜ |
| 6 | DMZ (20) | ⬜ |
| 7 | Invités (30) | ⬜ |
| 8 | Bastion (50) | ⬜ |
| 9 | Pare-feu | ⬜ |
| 10 | Durcissement et sauvegardes | ⬜ |
| 11 | Supervision (option) | ⬜ |
| 12 | Documentation | ⬜ |

## Documentation par phase

- [Phase 0 — Préparation et conventions](docs/00-preparation.md)
- [Phase 1 — Réseaux VMware](docs/01-reseaux-vmware.md)

## Environnement

- Hôte : Windows, VMware Workstation Pro (hyperviseur de type 2)
- 32 Go RAM, Intel Core Ultra 9 (8 cœurs), 2 To de disque
- Projet conçu à l'origine pour Proxmox VE, déployé sur VMware à cause des limites matérielles (détails dans la documentation finale)

## Auteur

Slimane Bouaroua — Master 2 Ingénierie Réseaux et Systèmes
v1 réalisée en trinôme avec A. Merabtene et L. Abdessalam (TER M1, UVSQ / Université Paris-Saclay).
