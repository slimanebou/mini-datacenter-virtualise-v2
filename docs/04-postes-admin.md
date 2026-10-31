# Phase 4 — Postes admin (Admin-40)

Objectif : créer le poste d'administration, joint au domaine, qui obtient son adresse du DC par le relais DHCP de pfSense. C'est aussi depuis ce poste que la GUI de pfSense est utilisée pour la première fois.

## Configuration

Windows 11 Pro — 4 Go RAM, 2 vCPU, 60 Go, UEFI + Secure Boot + vTPM, une carte sur `LAN-40-ADMIN`.

| Élément | Valeur |
|---|---|
| Nom | pc-admin.datacenter.lan |
| Adressage | DHCP via relais pfSense (bail obtenu : 192.168.40.100) |
| DNS | 192.168.10.10 (dc01) |
| Domaine | datacenter.lan, compte machine dans CN=Computers |
| Heure | synchronisée sur dc01 |

### pfSense

- Assistant initial : hostname `pfsense`, domaine `datacenter.lan`, fuseau Europe/Paris, mot de passe admin changé.
- WAN : option *Block RFC1918 Private Networks* désactivée, car le WAN est lui-même dans un réseau privé (VMnet8). Sans ça, le port forwarding ne serait pas testable depuis l'hôte.
- Interfaces renommées : SERVEURS (OPT1), DMZ (OPT2), INVITES (OPT3), BASTION (OPT4), DATA (OPT5).
- DHCP Relay : interface LAN → serveur 192.168.10.10. Le serveur DHCP de pfSense est désactivé sur toutes les interfaces (condition pour activer le relais).
- Règle temporaire sur SERVEURS : UDP de 192.168.10.10 vers 192.168.40.1 port 67 (retour du DC vers l'agent relais).

### Fonctionnement du relais

1. Le poste envoie un DHCPDISCOVER en broadcast sur la zone 40.
2. pfSense le capte, inscrit 192.168.40.1 dans le champ `giaddr` et le transmet en unicast au DC.
3. Le DC choisit l'étendue Admin-40 grâce à ce `giaddr` et répond à 192.168.40.1.
4. pfSense remet l'offre au poste.

## Preuves

| Test | Résultat |
|---|---|
| `ipconfig /all` | 192.168.40.100, passerelle 192.168.40.1, serveur DHCP et DNS 192.168.10.10 |
| `Test-ComputerSecureChannel` | True |
| `$env:LOGONSERVER` | \\DC01 |
| `w32tm /query /source` | dc01.datacenter.lan |
| `Get-DhcpServerv4Lease` (sur dc01) | bail actif pour pc-admin |
| `Resolve-DnsName pc-admin.datacenter.lan` | 192.168.40.100 |
| `Get-ADComputer pc-admin` | compte machine présent |
| Tableau de bord pfSense | utilisateur admin connecté depuis 192.168.40.100 |

Snapshots : `P04-pcadmin-ok`, `P04-pfsense-relais`.

## Limites et difficultés

- La zone 40 utilise encore la règle par défaut de pfSense « LAN → any ». Elle sera restreinte en phase 9 (authentification AD, bastion, GUI).
- Problème d'ordre résolu par une IP fixe temporaire : le poste avait besoin du relais pour obtenir une IP, mais il fallait la GUI pour configurer le relais.
- Windows 11 exige un vTPM et le Secure Boot, et l'installation hors ligne nécessite de contourner l'obligation de compte en ligne.
- pfSense 2.8.1 est disponible ; le projet reste en 2.7.2 pour ne pas changer de version en cours de route.