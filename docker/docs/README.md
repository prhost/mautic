# Mautic Docker - Documentação

## Estrutura do Projeto

```
mautic/
├── docker-compose.yml          # Docker Compose na raiz
├── .env                        # Variáveis de ambiente na raiz
├── docker/
│   ├── Dockerfile              # Imagem do Mautic
│   ├── env.example             # Exemplo de variáveis
│   ├── nginx/                  # Configurações do Nginx (comentado - usando Nginx Proxy Manager)
│   ├── mysql/                  # Scripts de inicialização do MySQL
│   ├── supervisor/             # Configurações do Supervisor
│   ├── scripts/
│   │   ├── setup.sh           # Script de configuração inicial
│   │   ├── update.sh          # Script de atualização
│   │   └── backup.sh          # Script de backup
│   ├── backups/               # Diretório de backups
│   └── docs/                  # Esta documentação
├── setup.sh                   # Script de setup na raiz
└── update.sh                  # Script de update na raiz
```

## Configuração Inicial

### 1. Primeira Execução

```bash
# Na raiz do projeto
./setup.sh
```

Este script irá:
- Verificar se o Docker está rodando
- Criar o arquivo `.env` se não existir
- Criar diretórios necessários
- Construir e iniciar os containers
- Configurar permissões

### 2. Configurar Variáveis de Ambiente

Edite o arquivo `.env` na raiz do projeto:

```bash
# Configurações do MySQL
MYSQL_ROOT_PASSWORD=sua_senha_root
MYSQL_DATABASE=mautic
MYSQL_USER=mautic
MYSQL_PASSWORD=sua_senha_mautic

# Configurações do Mautic
MAUTIC_SECRET_KEY=sua_chave_secreta_aqui
MAUTIC_SITE_URL=http://localhost
MAUTIC_LOCALE=pt_BR
MAUTIC_TIMEZONE=America/Sao_Paulo

# Configurações de Email
MAUTIC_MAILER_DSN=smtp://seu_smtp:587

# Ambiente
APP_ENV=prod
APP_DEBUG=0
```

## Atualizações

### Atualização Geral

Após fazer `git pull` para obter as últimas alterações:

```bash
# Na raiz do projeto
./update.sh
```

Este script irá:
- Fazer backup automático dos dados
- Parar os containers
- Atualizar imagens Docker
- Reconstruir a imagem do Mautic
- Executar migrações do banco
- Limpar cache e gerar assets
- Reiniciar os containers

### Atualização Manual

```bash
# Backup
cd docker && ./scripts/backup.sh

# Parar containers
docker compose down

# Atualizar código (git pull)

# Reconstruir e iniciar
docker compose build --no-cache mautic
docker compose up -d

# Migrações
docker compose exec -T mautic php bin/console doctrine:schema:update --force --env=prod
docker compose exec -T mautic php bin/console doctrine:migrations:migrate --no-interaction --env=prod

# Limpar cache e gerar assets
docker compose exec -T mautic php bin/console cache:clear --env=prod
docker compose exec -T mautic php bin/console mautic:assets:generate --env=prod
```

## Backup e Restauração

### Backup Automático

O backup é executado automaticamente durante as atualizações, mas você pode fazer backup manual:

```bash
cd docker && ./scripts/backup.sh
```

### Restauração

```bash
# Parar containers
docker compose down

# Restaurar banco de dados
docker compose up -d mysql
sleep 30
docker compose exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" < backup_database.sql

# Restaurar volumes
docker run --rm -v mautic_data:/data -v /caminho/para/backup:/backup alpine tar xzf /backup/volumes.tar.gz

# Reiniciar todos os containers
docker compose up -d
```

## Serviços

### Containers Principais

- **mautic_app**: Aplicação Mautic (PHP 8.2 + FPM)
- **mautic_mysql**: Banco de dados MySQL 8.0
- **mautic_redis**: Cache Redis 7
- **mautic_nginx**: Proxy reverso Nginx (comentado - usando Nginx Proxy Manager)

### Container Opcional

- **mautic_worker**: Worker para processamento de filas
  ```bash
  docker compose --profile worker up -d
  ```

## Volumes Persistentes

- `mysql_data`: Dados do MySQL
- `redis_data`: Dados do Redis
- `mautic_data`: Dados da aplicação (/var/www/html/var)
- `mautic_media`: Mídia do Mautic (/var/www/html/media)
- `mautic_logs`: Logs da aplicação
- `mautic_cache`: Cache da aplicação
- `mautic_tmp`: Arquivos temporários
- `mautic_files`: Arquivos da aplicação

## Comandos Úteis

### Logs

```bash
# Todos os serviços
docker compose logs -f

# Serviço específico
docker compose logs -f mautic
docker compose logs -f mysql
```

### Acesso ao Container

```bash
# Acessar Mautic
docker compose exec mautic bash

# Acessar MySQL
docker compose exec mysql mysql -u root -p

# Acessar Redis
docker compose exec redis redis-cli
```

### Comandos Mautic

```bash
# Limpar cache
docker compose exec mautic php bin/console cache:clear --env=prod

# Gerar assets
docker compose exec mautic php bin/console mautic:assets:generate --env=prod

# Executar migrações
docker compose exec mautic php bin/console doctrine:migrations:migrate --no-interaction --env=prod

# Verificar status
docker compose exec mautic php bin/console mautic:status --env=prod
```

## Troubleshooting

### Problemas de Permissão

Se o Mautic não conseguir escrever no arquivo de configuração:

```bash
docker compose exec mautic chown -R www-data:www-data /var/www/html/config/
docker compose exec mautic chmod -R 775 /var/www/html/config/
```

### Problemas de Migração

Se as migrações falharem:

```bash
# Atualizar schema primeiro
docker compose exec mautic php bin/console doctrine:schema:update --force --env=prod

# Depois executar migrações
docker compose exec mautic php bin/console doctrine:migrations:migrate --no-interaction --env=prod
```

### Problemas de Conectividade

Verificar se todos os containers estão rodando:

```bash
docker compose ps
```

### Limpar Tudo e Recomeçar

```bash
# Parar e remover containers
docker compose down

# Remover volumes (CUIDADO: perde todos os dados)
docker volume rm mautic_mysql_data mautic_redis_data mautic_mautic_data mautic_mautic_media

# Reconstruir
docker compose build --no-cache
docker compose up -d
```

## Portas

- **9000**: PHP-FPM (Mautic)
- **3306**: MySQL
- **6379**: Redis

## Requisitos

- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM mínimo
- 10GB espaço em disco

## Segurança

- Configure senhas fortes no `.env`
- Use HTTPS em produção
- Configure firewall adequadamente
- Mantenha as imagens atualizadas
- Faça backups regulares
