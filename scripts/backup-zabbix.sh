#!/bin/bash

# Script de sauvegarde Zabbix
# Auteur: EL MOUTAOUAKIL Abdellah
# Date: 2026-01-02

# Configuration
BACKUP_DIR="/backup/zabbix"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="zabbix_backup_${DATE}"
ZABBIX_COMPOSE_DIR="/home/ubuntu/zabbix"
DB_CONTAINER="zabbix-db"
DB_NAME="zabbix"
DB_USER="zabbix"
DB_PASSWORD="zabbix_password"
RETENTION_DAYS=7

echo "🔄 Démarrage de la sauvegarde Zabbix - ${DATE}"

# Création du répertoire de sauvegarde
mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"

# Sauvegarde de la base de données PostgreSQL
echo "📊 Sauvegarde de la base de données..."
cd "$ZABBIX_COMPOSE_DIR"

docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" -h localhost "$DB_NAME" > "${BACKUP_DIR}/${BACKUP_NAME}/zabbix_db_${DATE}.sql"

if [ $? -eq 0 ]; then
    echo "✅ Base de données sauvegardée avec succès"
else
    echo "❌ Erreur lors de la sauvegarde de la base de données"
    exit 1
fi

# Sauvegarde des volumes Docker
echo "💾 Sauvegarde des volumes Docker..."
docker run --rm \
    -v zabbix_zabbix-db-data:/source:ro \
    -v "${BACKUP_DIR}/${BACKUP_NAME}":/backup \
    alpine \
    tar czf /backup/zabbix_db_volume_${DATE}.tar.gz -C /source .

docker run --rm \
    -v zabbix_zabbix-server-data:/source:ro \
    -v "${BACKUP_DIR}/${BACKUP_NAME}":/backup \
    alpine \
    tar czf /backup/zabbix_server_volume_${DATE}.tar.gz -C /source .

echo "✅ Volumes Docker sauvegardés"

# Sauvegarde du docker-compose.yml
echo "🐳 Sauvegarde de la configuration Docker..."
cp "${ZABBIX_COMPOSE_DIR}/docker-compose.yml" "${BACKUP_DIR}/${BACKUP_NAME}/docker-compose_${DATE}.yml"

# Sauvegarde des configurations personnalisées
echo "⚙️ Sauvegarde des configurations..."
mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}/configs"

# Si des configurations personnalisées existent
if [ -d "${ZABBIX_COMPOSE_DIR}/configs" ]; then
    cp -r "${ZABBIX_COMPOSE_DIR}/configs/"* "${BACKUP_DIR}/${BACKUP_NAME}/configs/"
fi

# Compression finale
echo "🗜️ Compression de la sauvegarde..."
cd "$BACKUP_DIR"
tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Sauvegarde compressée: ${BACKUP_NAME}.tar.gz"
    rm -rf "$BACKUP_NAME"
else
    echo "❌ Erreur lors de la compression"
    exit 1
fi

# Nettoyage des anciennes sauvegardes
echo "🧹 Nettoyage des anciennes sauvegardes (>${RETENTION_DAYS} jours)..."
find "$BACKUP_DIR" -name "zabbix_backup_*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete

# Calcul de la taille
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)

# Rapport final
echo ""
echo "🎉 Sauvegarde terminée avec succès !"
echo "========================================"
echo "Fichier: ${BACKUP_NAME}.tar.gz"
echo "Taille: $BACKUP_SIZE"
echo "Emplacement: $BACKUP_DIR"
echo "Date: $(date)"
echo "========================================"
echo ""

# Vérification de l'intégrité
echo "🔍 Vérification de l'intégrité..."
if tar tzf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" >/dev/null 2>&1; then
    echo "✅ Archive intègre"
else
    echo "❌ Archive corrompue !"
    exit 1
fi

# Script de restauration automatique
cat > "${BACKUP_DIR}/restore_${BACKUP_NAME}.sh" << EOF
#!/bin/bash
# Script de restauration automatique pour ${BACKUP_NAME}
# Généré le: $(date)

BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
RESTORE_DIR="/tmp/zabbix_restore_${DATE}"
ZABBIX_DIR="${ZABBIX_COMPOSE_DIR}"

echo "🔄 Restauration de Zabbix depuis \$BACKUP_FILE"

# Extraction
mkdir -p "\$RESTORE_DIR"
tar xzf "\$BACKUP_FILE" -C "\$RESTORE_DIR"

# Arrêt des services
cd "\$ZABBIX_DIR"
docker-compose down

# Restauration des volumes
docker volume rm zabbix_zabbix-db-data zabbix_zabbix-server-data 2>/dev/null || true
docker volume create zabbix_zabbix-db-data
docker volume create zabbix_zabbix-server-data

docker run --rm \\
    -v "\$RESTORE_DIR/${BACKUP_NAME}/zabbix_db_volume_${DATE}.tar.gz":/backup.tar.gz \\
    -v zabbix_zabbix-db-data:/target \\
    alpine \\
    sh -c "cd /target && tar xzf /backup.tar.gz"

docker run --rm \\
    -v "\$RESTORE_DIR/${BACKUP_NAME}/zabbix_server_volume_${DATE}.tar.gz":/backup.tar.gz \\
    -v zabbix_zabbix-server-data:/target \\
    alpine \\
    sh -c "cd /target && tar xzf /backup.tar.gz"

# Restauration de la configuration
cp "\$RESTORE_DIR/${BACKUP_NAME}/docker-compose_${DATE}.yml" "\$ZABBIX_DIR/docker-compose.yml"

# Redémarrage
docker-compose up -d

echo "✅ Restauration terminée"
rm -rf "\$RESTORE_DIR"
EOF

chmod +x "${BACKUP_DIR}/restore_${BACKUP_NAME}.sh"

echo "📝 Script de restauration créé: restore_${BACKUP_NAME}.sh"
echo "✨ Sauvegarde complète terminée !"