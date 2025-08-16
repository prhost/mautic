#!/bin/bash

# Mautic Docker Setup Script
# Script para configuração inicial

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

echo "🚀 Mautic Docker Setup"
echo "======================"

# Verificar se estamos na pasta correta
if [ ! -f "../docker-compose.yml" ]; then
    log_error "Execute este script da pasta raiz do projeto Mautic"
    exit 1
fi

# Verificar Docker
log_info "Verificando Docker..."
if ! docker info > /dev/null 2>&1; then
    log_error "Docker não está rodando"
    exit 1
fi

# Verificar se o .env existe
if [ ! -f "../.env" ]; then
    log_info "Criando arquivo .env..."
    cp env.example ../.env
    log_warning "Configure o arquivo .env antes de continuar!"
    echo "   - MYSQL_ROOT_PASSWORD"
    echo "   - MYSQL_PASSWORD"
    echo "   - MAUTIC_SECRET_KEY"
    echo "   - MAUTIC_SITE_URL"
    read -p "Pressione Enter após configurar..."
fi

# Criar diretórios
log_info "Criando diretórios..."
mkdir -p backups
# mkdir -p nginx/ssl  # Não necessário sem Nginx local

# Construir e iniciar
log_info "Construindo containers..."
cd .. && docker compose build

log_info "Iniciando containers..."
docker compose up -d

# Aguardar inicialização
log_info "Aguardando inicialização..."
sleep 60

# Corrigir permissões do config
log_info "Corrigindo permissões..."
docker compose exec -T mautic_app chown -R www-data:www-data /var/www/html/config/
docker compose exec -T mautic_app chmod -R 775 /var/www/html/config/
docker compose exec -T mautic_app touch /var/www/html/config/local.php
docker compose exec -T mautic_app chown www-data:www-data /var/www/html/config/local.php
docker compose exec -T mautic_app chmod 664 /var/www/html/config/local.php

# Verificar status
log_info "Verificando status..."
docker compose ps

echo ""
log_success "Setup concluído!"
echo "🌐 Acesse: http://localhost"
echo "📊 Logs: docker compose logs -f"

