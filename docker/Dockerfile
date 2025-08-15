FROM php:8.2-fpm-alpine

# Instalar apenas dependências essenciais
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    icu-dev \
    oniguruma-dev \
    libzip-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    imap-dev \
    openssl-dev \
    autoconf \
    g++ \
    make \
    supervisor \
    cronie \
    mysql-client \
    libcurl \
    curl-dev \
    nodejs \
    npm \
    && rm -rf /var/cache/apk/*

# Configurar e instalar extensões PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-configure imap --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        mbstring \
        xml \
        curl \
        zip \
        intl \
        gd \
        imap \
        opcache

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Criar usuário não-root
RUN addgroup -g 1000 mautic && \
    adduser -D -s /bin/sh -u 1000 -G mautic mautic

# Configurar diretórios
WORKDIR /var/www/html

# Copiar apenas arquivos essenciais primeiro
COPY --chown=mautic:mautic composer.json composer.lock ./
COPY --chown=mautic:mautic app/composer.json app/

# Instalar dependências do Composer (pular scripts que falham)
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# Copiar o resto dos arquivos
COPY --chown=mautic:mautic . .

# Instalar dependências do Node.js
RUN npm install

# Criar diretórios necessários e configurar permissões
RUN mkdir -p var/cache var/logs var/tmp media && \
    chown -R mautic:mautic /var/www/html && \
    chmod -R 777 var/cache var/logs var/tmp media && \
    chmod -R 775 config/ && \
    touch config/local.php && \
    chown www-data:www-data config/local.php && \
    chmod 664 config/local.php

# Configurar PHP para produção
RUN echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini && \
    echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini && \
    echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini && \
    echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini && \
    echo "zend.assertions = -1" >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini

# Configurar OPcache
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.interned_strings_buffer=16" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.revalidate_freq=0" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.fast_shutdown=1" >> /usr/local/etc/php/conf.d/opcache.ini

# Copiar arquivos de configuração do supervisor
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/supervisor/cron.conf /etc/supervisor/conf.d/cron.conf
COPY docker/supervisor/mautic-cron /etc/cron.d/mautic-cron

# Criar diretórios necessários
RUN mkdir -p /var/log/supervisor /var/run/supervisor && \
    chown -R mautic:mautic /var/log/supervisor /var/run/supervisor

# Script de inicialização
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expor porta
EXPOSE 9000

# Comando padrão
CMD ["/entrypoint.sh"]

