#!/bin/sh
set -e

echo "Iniciando Mautic..."

# Configurar permissões
chown -R mautic:mautic /var/www/html
chmod -R 777 var/cache var/logs var/tmp media

# Iniciar supervisor (que gerencia cron jobs)
echo "Iniciando supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

