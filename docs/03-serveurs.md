# Phase 3 — Serveurs (Dc-10)

Objectif : créer le contrôleur de domaine `dc01`, qui porte l'identité (AD DS), la résolution de noms (DNS), l'adressage des zones 10 et 40 (DHCP) et l'heure du domaine (NTP).

## Configuration

Windows Server 2022 Standard (Desktop Experience) — 4 Go RAM, 4 vCPU, 60 Go, une carte sur `LAN-10-SERVEURS`.

| Élément | Valeur |
|---|---|
| Nom / IP | dc01 / 192.168.10.10/24, passerelle 192.168.10.1 |
| Domaine | datacenter.lan (NetBIOS : DATACENTER) |
| DNS du serveur | 127.0.0.1 (lui-même) |
| Redirecteur DNS | 192.168.10.1 (DNS Resolver de pfSense) |
| Zones inversées | 10.168.192.in-addr.arpa, 40.168.192.in-addr.arpa |
| DHCP — Serveurs-10 | 192.168.10.100 – .199, routeur .1, DNS 192.168.10.10 |
| DHCP — Admin-40 | 192.168.40.100 – .199, routeur .1, DNS 192.168.10.10 (servie via relais pfSense) |
| NTP | dc01 se synchronise sur pfSense (192.168.10.1) et sert d'heure de référence au domaine |

### Règles temporaires sur pfSense (OPT1)

Ajoutées à la console avec `easyrule`, car la GUI n'est pas encore accessible :

| Source | Destination | Port | Rôle |
|---|---|---|---|
| 192.168.10.10 | 192.168.10.1 | UDP/TCP 53 | Résolution DNS par pfSense |
| 192.168.10.10 | 192.168.10.1 | UDP 123 | Synchronisation de l'heure |

Elles seront remplacées par les règles définitives en phase 9.

## Preuves

| Test | Résultat |
|---|---|
| `Get-ADDomain` | DNSRoot datacenter.lan, PDCEmulator dc01.datacenter.lan |
| `Resolve-DnsName dc01.datacenter.lan` | 192.168.10.10 |
| `Resolve-DnsName debian.org` | Résolu via le redirecteur pfSense |
| `Get-DhcpServerInDC` | dc01 autorisé dans AD |
| `Get-DhcpServerv4Scope` | 2 étendues actives (10 et 40) |
| `w32tm /query /status` | Source 192.168.10.1, stratum 3 |

Snapshot : `P03-dc01-ad-ok`.

## Difficultés

- `dcdiag` a signalé un échec des tests SystemLog et DFSREvent. La cause est un arrêt brutal de la VM (Power Off) qui a laissé des événements d'erreur dans les journaux. Il ne s'agit pas d'une erreur de configuration : SYSVOL et NETLOGON sont bien partagés. Leçon : un contrôleur de domaine s'arrête toujours proprement (Shut Down Guest).
- Le redirecteur DNS existait déjà après la promotion : Windows reprend le serveur DNS configuré avant `Install-ADDSForest` et l'ajoute comme redirecteur.