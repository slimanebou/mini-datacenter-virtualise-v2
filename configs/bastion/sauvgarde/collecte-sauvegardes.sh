#!/bin/bash
# Collecte les sauvegardes du datacenter sur le bastion
set -euo pipefail
K="-i /home/bouaroua/.ssh/backup_ed25519 -o BatchMode=yes"
D=/srv/backups; J=$(date +%F)
mkdir -p "$D"/{db,pfsense,bastion}

# 1. Dumps MariaDB depuis db
scp $K -p 'bouaroua@192.168.60.10:/var/backups/mariadb/*.sql.gz' "$D/db/"

# 2. Configuration complète de pfSense
scp $K admin@192.168.50.1:/cf/conf/config.xml "$D/pfsense/config-$J.xml"

# 3. Base Guacamole (utilisateurs, connexions, historique) et configuration du bastion
cd /home/bouaroua/bastion
docker compose exec -T postgres pg_dump -U guacamole_user guacamole_db | gzip > "$D/bastion/guacamole-$J.sql.gz"
tar czf "$D/bastion/bastion-conf-$J.tgz" --exclude=recordings --exclude=certs/bastion.key -C /home/bouaroua bastion

# Rotation : 14 jours
find "$D" -type f -mtime +14 -delete
chmod -R o-rwx "$D"
