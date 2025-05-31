FROM php:8.2-cli

RUN apt-get update && apt-get install -y \
    git unzip zip libicu-dev libonig-dev libxml2-dev \
    && docker-php-ext-install intl pdo pdo_mysql mbstring xml opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Создаём пользователя appuser
RUN useradd -m appuser

# Создаём рабочую директорию и даём права appuser
WORKDIR /app
RUN chown -R appuser:appuser /app

# Переключаемся на пользователя appuser
USER appuser

# Копируем файлы composer.json и composer.lock (чтобы установить зависимости)
COPY --chown=appuser:appuser composer.json composer.lock ./

# Устанавливаем зависимости composer
RUN composer install --no-dev --optimize-autoloader

# Копируем остальной код (тоже с нужными правами)
COPY --chown=appuser:appuser . .

# Кэшируем Symfony для prod
RUN php bin/console cache:clear --env=prod --no-debug
RUN php bin/console cache:warmup --env=prod --no-debug

CMD ["php", "bin/console", "server:run", "0.0.0.0:8000"]
