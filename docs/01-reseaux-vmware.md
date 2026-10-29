# Phase 1 — Réseaux VMware

Objectif : créer les « câbles » du datacenter avant les machines. Une sortie Internet (VMnet8 en NAT) et six switchs virtuels isolés (LAN Segments). pfSense est la seule VM branchée à tous : c'est le seul pont entre les zones.

## Réseaux créés

| Réseau VMware | Type | Rôle |
|---|---|---|
| VMnet8 | NAT, DHCP VMware actif | Sortie Internet de pfSense (WAN) |
| `LAN-40-ADMIN` | LAN Segment | Postes d'administration |
| `LAN-10-SERVEURS` | LAN Segment | Contrôleur de domaine |
| `LAN-20-DMZ` | LAN Segment | Serveur web exposé |
| `LAN-30-INVITES` | LAN Segment | Client invité |
| `LAN-50-BASTION` | LAN Segment | Bastion Guacamole |
| `LAN-60-DATA` | LAN Segment | Base de données |

Un LAN Segment n'a ni DHCP VMware ni carte sur l'hôte Windows : il est totalement isolé.

## Câblage de pfSense-gw

| Carte VMware | Connexion | MAC | Interface pfSense prévue |
|---|---|---|---|
| Network Adapter | NAT (VMnet8) | voir em0 dans pfSense | WAN |
| Network Adapter 2 | `LAN-40-ADMIN` | 00:0C:29:F8:A7:FE | LAN (GUI + anti-lockout) |
| Network Adapter 3 | `LAN-10-SERVEURS` | 00:0C:29:F8:A7:08 | OPT1 |
| Network Adapter 4 | `LAN-20-DMZ` | 00:0C:29:F8:A7:12 | OPT2 |
| Network Adapter 5 | `LAN-30-INVITES` | 00:0C:29:F8:A7:1C | OPT3 |
| Network Adapter 6 | `LAN-50-BASTION` | 00:0C:29:F8:A7:26 | OPT4 |
| Network Adapter 7 | `LAN-60-DATA` | 00:0C:29:F8:A7:30 | OPT5 |

La zone admin est volontairement sur l'interface « LAN » de pfSense : c'est là que pfSense place sa règle anti-lockout (accès garanti à la GUI).

## Preuves

- Paramètres de pfSense-gw : 1 carte NAT + 6 cartes LAN Segment.
- Les MAC relevées servent à identifier les interfaces en phase 2.

## Difficultés

- La vérification par lecture du fichier `.vmx` (PowerShell `Select-String`) n'a pas fonctionné. L'affectation des segments est contrôlée en phase 2 via les adresses MAC affichées par pfSense.
