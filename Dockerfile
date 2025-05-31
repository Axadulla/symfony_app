# Используем официальный PHP образ с необходимыми расширениями (например, php8.2-fpm)
FROM php:8.2-fpm

# Устанавливаем необходимые системные зависимости
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libicu-dev \
    libonig-dev \
    libzip-dev \
    zip \
    curl \
    && docker-php-ext-install intl mbstring zip pdo pdo_mysql

# Устанавливаем Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Копируем файлы проекта в контейнер
WORKDIR /app
COPY . .

# Устанавливаем переменные окружения для продакшена
ENV APP_ENV=prod
ENV APP_DEBUG=0

# Устанавливаем зависимости без dev-пакетов и без выполнения скриптов
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Запускаем вручную необходимые post-install скрипты (очистка кэша и прочее)
RUN php bin/console cache:clear --env=prod --no-debug
RUN php bin/console cache:warmup --env=prod --no-debug

# Открываем порт, который будет слушать PHP-FPM (обычно 9000)
EXPOSE 9000

# Запускаем PHP-FPM сервер
CMD ["php-fpm"]
