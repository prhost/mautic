#!/bin/bash

# Mautic Docker Update Script
# Script completo para atualizar o Mautic após git pull

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🚀 Mautic Docker Update"
echo "======================="

# Verificar se estamos na pasta correta
if [ ! -f "../docker-compose.yml" ]; then
    log_error "Execute este script da pasta raiz do projeto Mautic"
    exit 1
fi

# Verificar se o Docker está rodando
log_info "Verificando Docker..."
if ! docker info > /dev/null 2>&1; then
    log_error "Docker não está rodando"
    exit 1
fi

# Fazer backup antes da atualização
log_info "Fazendo backup dos dados..."
./scripts/backup.sh

# Parar containers
log_info "Parando containers..."
cd .. && docker compose down

# Fazer pull das imagens mais recentes
log_info "Atualizando imagens Docker..."
docker compose pull

# Não precisamos reconstruir a imagem do Mautic a cada atualização
# já que o código-fonte está montado como volume
log_info "Pulando reconstrução da imagem Mautic (usando volumes)..."

# Iniciar containers
log_info "Iniciando containers..."
docker compose up -d

# Aguardar inicialização
log_info "Aguardando inicialização..."
sleep 30

# Atualizar dependências do Composer
log_info "Atualizando dependências do Composer..."
docker compose exec -T mautic composer install --no-dev --optimize-autoloader --no-interaction

# Atualizar dependências do Node.js
log_info "Atualizando dependências do Node.js..."
docker compose exec -T mautic npm install

# Compilar assets do Node.js
log_info "Compilando assets do Node.js..."
docker compose exec -T mautic npm run build

# Corrigir permissões do config
log_info "Corrigindo permissões..."
docker compose exec -T mautic chown -R www-data:www-data /var/www/html/config/
docker compose exec -T mautic chmod -R 775 /var/www/html/config/
docker compose exec -T mautic touch /var/www/html/config/local.php
docker compose exec -T mautic chown www-data:www-data /var/www/html/config/local.php
docker compose exec -T mautic chmod 664 /var/www/html/config/local.php

# Executar migrações
log_info "Executando migrações..."
docker compose exec -T mautic php bin/console doctrine:schema:update --force --env=prod
docker compose exec -T mautic php bin/console doctrine:migrations:migrate --no-interaction --env=prod

# Limpar cache
log_info "Limpando cache..."
docker compose exec -T mautic php bin/console cache:clear --env=prod

# Gerar assets
log_info "Gerando assets..."
docker compose exec -T mautic php bin/console mautic:assets:generate --env=prod

# Verificar status
log_info "Verificando status..."
docker compose ps

# Testar conectividade
log_info "Testando conectividade..."
if curl -s http://localhost > /dev/null; then
    log_success "Mautic está funcionando"
else
    log_warning "Mautic pode estar ainda inicializando"
fi

echo ""
log_success "Atualização concluída com sucesso!"
echo "🌐 Acesse: http://localhost"
echo "📊 Logs: docker compose logs -f"

