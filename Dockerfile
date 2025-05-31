# Используем официальный PHP образ с необходимыми расширениями
FROM php:8.2-cli

# Устанавливаем системные зависимости и расширения PHP, нужные для Symfony и Doctrine
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    && docker-php-ext-install intl pdo pdo_mysql zip opcache

# Устанавливаем composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Создаем рабочую директорию
WORKDIR /app

# Копируем composer файлы сначала (для кэширования слоев)
COPY composer.json composer.lock ./

# Устанавливаем зависимости без dev, без автозагрузки и без скриптов
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Копируем всё приложение в контейнер
COPY . .

# Устанавливаем symfony/runtime (обязательно для Symfony 6+)
RUN composer require symfony/runtime --no-interaction --no-progress --no-scripts

# Запускаем post-install скрипты вручную (кэш)
RUN php bin/console cache:clear --env=prod --no-debug
RUN php bin/console cache:warmup --env=prod --no-debug

# Открываем порт (если нужен встроенный сервер PHP)
EXPOSE 8000

# Команда по умолчанию (запуск PHP сервера Symfony)
CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]
