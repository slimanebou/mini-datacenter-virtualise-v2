# Phase 2 — pfSense

Objectif : installer le pare-feu central qui route entre les 6 zones, fait le NAT vers Internet et sert de DNS. Sans règle, les interfaces OPT bloquent tout (default deny).

## Configuration

Version : pfSense CE 2.7.2 — 2 Go RAM, 2 vCPU, 20 Go.

| Interface pfSense | Carte FreeBSD | Segment | IP |
|---|---|---|---|
| WAN | em0 | VMnet8 (NAT) | 192.168.204.137 (DHCP VMware) |
| LAN (admin 40) | em1 | LAN-40-ADMIN | 192.168.40.1/24 |
| OPT1 (serveurs 10) | em2 | LAN-10-SERVEURS | 192.168.10.1/24 |
| OPT2 (DMZ 20) | em3 | LAN-20-DMZ | 192.168.20.1/24 |
| OPT3 (invités 30) | em4 | LAN-30-INVITES | 192.168.30.1/24 |
| OPT4 (bastion 50) | em5 | LAN-50-BASTION | 192.168.50.1/24 |
| OPT5 (data 60) | em6 | LAN-60-DATA | 192.168.60.1/24 |

- Serveur DHCP de pfSense désactivé partout (le DC fera le DHCP, via relais pour la zone 40).
- NAT sortant en mode automatique.
- DNS Resolver (Unbound) actif.
- Configuration faite à la console : la GUI sera testée en phase 4, quand un poste existera dans la zone 40.

## Preuves

| Test | Commande | Résultat |
|---|---|---|
| IP des interfaces | `ifconfig` | 7 interfaces, chacune avec son IP prévue |
| Sortie Internet | `ping -c 3 8.8.8.8` | 3/3 réponses, ≈ 16 ms |
| DNS Resolver | `host debian.org 127.0.0.1` | résolution OK |
| NAT des 6 zones | `pfctl -t tonatsubnets -T show` | 6 réseaux internes listés |

Snapshot : `P02-pfsense-ok`.

## Difficultés

- `pfctl -s nat` n'affiche que 4 règles : pfSense ne crée pas une règle par réseau, il regroupe les réseaux internes dans la table `tonatsubnets`. La preuve se fait en lisant cette table.