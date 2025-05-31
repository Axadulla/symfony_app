FROM php:8.2-cli

# Установка зависимостей системы, PHP-расширений и composer
RUN apt-get update && apt-get install -y unzip git zip libzip-dev \
    && docker-php-ext-install zip pdo pdo_mysql

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Создаем пользователя для работы с приложением
RUN useradd -m appuser

WORKDIR /app

# Копируем composer.json и composer.lock с нужными правами
COPY --chown=appuser:appuser composer.json composer.lock ./

# Переключаемся на appuser
USER appuser

RUN composer install --no-dev --optimize-autoloader

# Копируем остальной код тоже с правами appuser
COPY --chown=appuser:appuser . .

# Очистка и прогрев кэша
RUN php bin/console cache:clear --env=prod --no-debug
RUN php bin/console cache:warmup --env=prod --no-debug

EXPOSE 8000

CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]
