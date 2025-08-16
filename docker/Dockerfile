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

# Criar diretórios necessários para volumes
RUN mkdir -p /var/www/html/app /var/www/html/var/cache /var/www/html/var/logs /var/www/html/var/tmp /var/www/html/media /var/www/html/config

# Não copiamos os arquivos do projeto aqui - serão montados como volumes

# Definir usuário mautic como proprietário dos diretórios
RUN chown -R mautic:mautic /var/www/html

# Não instalamos dependências do Node.js aqui - serão instaladas durante o processo de atualização

# Configurar permissões para os diretórios que serão montados como volumes
RUN chmod -R 777 var/cache var/logs var/tmp media && \
    chmod -R 775 config/

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
