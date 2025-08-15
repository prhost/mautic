#!/bin/bash

# Mautic Docker Backup Script

set -e

# Configurações
BACKUP_DIR="./docker/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="mautic_backup_$DATE"

echo "📦 Iniciando backup do Mautic..."

# Criar diretório de backup
mkdir -p "$BACKUP_DIR"

# Backup do banco de dados
echo "🗄️ Backup do banco de dados..."
cd .. && docker compose exec mysql mysqldump -u root -p"${MYSQL_ROOT_PASSWORD:-rootpassword}" \
    --single-transaction \
    --routines \
    --triggers \
    --all-databases > "docker/$BACKUP_DIR/${BACKUP_NAME}_database.sql"

# Backup dos volumes (apenas dados essenciais)
echo "💾 Backup dos volumes..."
docker run --rm \
    -v mautic_data:/data \
    -v mautic_media:/media \
    -v "$(pwd)/docker/$BACKUP_DIR:/backup" \
    alpine tar czf "/backup/${BACKUP_NAME}_volumes.tar.gz" /data /media

# Backup do Redis
echo "🔴 Backup do Redis..."
docker compose exec redis redis-cli BGSAVE
sleep 5
docker run --rm \
    -v mautic_redis_data:/data \
    -v "$(pwd)/docker/$BACKUP_DIR:/backup" \
    alpine tar czf "/backup/${BACKUP_NAME}_redis.tar.gz" /data

# Compactar tudo
echo "🗜️ Compactando backup..."
cd docker/$BACKUP_DIR
tar czf "${BACKUP_NAME}_complete.tar.gz" \
    "${BACKUP_NAME}_database.sql" \
    "${BACKUP_NAME}_volumes.tar.gz" \
    "${BACKUP_NAME}_redis.tar.gz"

# Limpar arquivos temporários
rm -f "${BACKUP_NAME}_database.sql" \
      "${BACKUP_NAME}_volumes.tar.gz" \
      "${BACKUP_NAME}_redis.tar.gz"

echo "✅ Backup concluído: $BACKUP_DIR/${BACKUP_NAME}_complete.tar.gz"

