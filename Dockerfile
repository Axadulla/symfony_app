# Используем официальный PHP 8.2 CLI образ
FROM php:8.2-cli

# Устанавливаем системные зависимости и расширения для Symfony и PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    unzip \
    git \
    zip \
    && docker-php-ext-install pdo_pgsql

# Копируем composer из официального образа composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Создаем пользователя с домашней директорией
RUN useradd -m symfonyuser

# Рабочая директория для приложения
WORKDIR /app

# Копируем все файлы в контейнер
COPY . /app

# Меняем владельца на нашего пользователя
RUN chown -R symfonyuser:symfonyuser /app

# Переключаемся на пользователя
USER symfonyuser

# Устанавливаем зависимости composer без dev и с оптимизацией автозагрузчика
RUN composer install --no-dev --optimize-autoloader

# Кэшируем конфигурацию и роуты для Symfony (если у тебя есть такие скрипты)
RUN php bin/console cache:clear --env=prod --no-debug
RUN php bin/console cache:warmup --env=prod --no-debug

# Открываем порт 10000 (или любой, который используешь)
EXPOSE 10000

# Команда запуска — встроенный PHP сервер, который слушает на 0.0.0.0:10000, корень — public
CMD ["php", "-S", "0.0.0.0:10000", "-t", "public"]
