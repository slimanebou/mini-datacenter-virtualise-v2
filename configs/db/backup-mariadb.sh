#!/bin/bash
# Dump cohérent de appdb (sans verrouiller les tables), compressé et horodaté
set -euo pipefail
DEST=/var/backups/mariadb
FICHIER="$DEST/appdb-$(date +%F_%H%M).sql.gz"
mariadb-dump --single-transaction --routines --events --databases appdb | gzip > "$FICHIER"
chgrp bouaroua "$FICHIER" && chmod 640 "$FICHIER"
# Rotation : on garde 7 jours
find "$DEST" -name 'appdb-*.sql.gz' -mtime +7 -delete
