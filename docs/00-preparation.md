# Phase 0 — Préparation et conventions

Objectif : fixer toutes les règles **avant** de créer la moindre VM, pour que chaque phase suivante applique les mêmes noms, les mêmes IP et la même méthode.

## 1. Plan d'adressage

Règle : **le 3e octet = le numéro de zone (VLAN)**. pfSense est toujours en `.1`.

| Zone | Réseau | Passerelle | Plage IP fixes | Plage DHCP | LAN Segment VMware |
|---|---|---|---|---|---|
| WAN | VMnet8 (NAT VMware) | DHCP VMware | — | — | `VMnet8` |
| Serveurs (10) | 192.168.10.0/24 | 192.168.10.1 | .10 – .49 | .100 – .199 | `LAN-10-SERVEURS` |
| DMZ (20) | 192.168.20.0/24 | 192.168.20.1 | .10 – .49 | aucune | `LAN-20-DMZ` |
| Invités (30) | 192.168.30.0/24 | 192.168.30.1 | .10 – .49 | aucune | `LAN-30-INVITES` |
| Postes admin (40) | 192.168.40.0/24 | 192.168.40.1 | .10 – .49 | .100 – .199 (DC, via relais) | `LAN-40-ADMIN` |
| Bastion (50) | 192.168.50.0/24 | 192.168.50.1 | .10 – .49 | aucune | `LAN-50-BASTION` |
| Données (60) | 192.168.60.0/24 | 192.168.60.1 | .10 – .49 | aucune | `LAN-60-DATA` |

Les plages `.2 – .9` et `.200 – .254` restent libres (réserve).

## 2. Inventaire des VMs

| Nom VMware | Hostname | FQDN | Rôle | IP | RAM | vCPU | Disque | Création | Phase |
|---|---|---|---|---|---|---|---|---|---|
| `pfSense-gw` | pfsense | pfsense.datacenter.lan | Pare-feu, routeur, NAT, DNS Resolver | `.1` partout | 2 Go | 2 | 20 Go | ISO pfSense | 2 |
| `Dc-10` | dc01 | dc01.datacenter.lan | AD DS, DNS, DHCP, NTP | 192.168.10.10 | 4 Go | 4 | 60 Go | ISO Windows Server 2022 | 3 |
| `Admin-40` | pc-admin | pc-admin.datacenter.lan | Poste d'administration | DHCP | 4 Go | 2 | 60 Go | ISO Windows 11 | 4 |
| `Db-60` | db01 | db01.datacenter.lan | MariaDB | 192.168.60.10 | 2 Go | 2 | 20 Go | Clone Debian 13 | 5 |
| `Web-20` | web01 | web01.datacenter.lan | Docker : Nginx + app | 192.168.20.10 | 2 Go | 2 | 20 Go | Clone Debian 13 | 6 |
| `Guest-30` | guest01 | — | Client invité | 192.168.30.10 | 2 Go | 2 | 20 Go | Clone Debian 13 | 7 |
| `Bastion-50` | bastion | bastion.datacenter.lan | Guacamole | 192.168.50.10 | 3 Go | 2 | 20 Go | Clone Debian 13 | 8 |

Total : ≈ 19 Go de RAM, 16 vCPU sur 8 cœurs physiques (sur-allocation acceptable en lab).

Domaine Active Directory : `datacenter.lan`.

## 3. Conventions

### VMware
- Dossier des VMs : dossier de bibliothèque VMware `TER - Mini Datacenter`
- Clones : **toujours en clone complet**, jamais en clone lié.
- **Une seule carte réseau par VM** (sauf pfSense) : impossible de contourner le pare-feu.

### Snapshots
Format : `P<phase>-<vm>-<état>`
Exemples : `P02-pfsense-ok`, `P03-dc01-ad-ok`, `P09-pfsense-avant-regles`.
Règle : un snapshot avant chaque changement risqué, un snapshot à la fin de chaque phase validée.

### Git
- Un commit par phase validée : `Phase N : <résumé>`.
- Jamais de secret dans le dépôt (mots de passe, clés privées, `config.xml` brut de pfSense).

### Comptes (appliqués en phase 10)
- Compte standard : `slimane`
- Compte d'administration séparé : `adm-slimane`

## 4. Arborescence du dépôt

```
mini-datacenter-virtualise-v2/
├── README.md              présentation, avancement, résultats
├── .gitignore
├── docs/
│   ├── 00-preparation.md  ce fichier
│   ├── 01-...md           une page par phase, créée au fil du projet
│   └── schema/            schéma de suivi + images
└── configs/               fichiers de configuration réels, par VM (créés au fil des phases)
```

## 5. Preuves de la phase

- Dépôt créé et poussé sur GitHub.
- Plan IP et conventions figés dans ce document.
