# Используем официальный PHP 8.2 CLI образ с Apache (если хочешь использовать встроенный сервер — можно php:8.2-cli)
FROM php:8.2-cli

# Устанавливаем системные зависимости и расширения для PostgreSQL и Symfony
RUN apt-get update && apt-get install -y \
    libpq-dev \
    unzip \
    git \
    zip \
    && docker-php-ext-install pdo_pgsql

# Устанавливаем Composer (используем официальный образ composer для копирования бинарника)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем все файлы проекта в контейнер
COPY . /app

# Устанавливаем зависимости composer (без dev)
RUN composer install --no-dev --optimize-autoloader

# Открываем порт, который будет слушать PHP встроенный сервер
EXPOSE 10000

# Запускаем встроенный сервер PHP на порту 10000, корень — папка public
CMD ["php", "-S", "0.0.0.0:10000", "-t", "public"]

RUN composer install --no-dev --optimize-autoloader

EXPOSE 10000