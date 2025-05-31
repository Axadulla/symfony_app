FROM php:8.2-cli

RUN apt-get update && apt-get install -y git unzip libzip-dev libicu-dev libonig-dev libxml2-dev zip \
    && docker-php-ext-install intl pdo pdo_mysql zip opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Копируем только файлы composer, чтобы кешировать установку зависимостей
COPY composer.json composer.lock ./

RUN composer install --no-dev --optimize-autoloader

# Теперь копируем остальной код
COPY . .

# Проверим, что symfony/runtime установлен
RUN ls -la vendor/symfony/runtime

# Кэшируем
RUN php bin/console cache:clear --env=prod --no-debug
RUN php bin/console cache:warmup --env=prod --no-debug

EXPOSE 8000

CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]
