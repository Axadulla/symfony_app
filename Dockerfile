# Используем официальный PHP CLI образ с нужными расширениями
FROM php:8.2-cli

# Устанавливаем системные зависимости и расширения PHP
RUN apt-get update && apt-get install -y \
    git unzip zip libicu-dev libonig-dev libxml2-dev \
    && docker-php-ext-install intl pdo pdo_mysql mbstring xml opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Устанавливаем Composer глобально
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Создаём рабочую директорию
WORKDIR /app

# Создаём пользователя appuser (без пароля) и задаём права
RUN useradd -m appuser

# Копируем весь исходный код проекта с нужными правами сразу
COPY --chown=appuser:appuser . .

# Переключаемся на пользователя appuser
USER appuser

# Устанавливаем зависимости composer без dev и с оптимизацией автозагрузчика
RUN composer install --no-dev --optimize-autoloader

# Очищаем и греем кеш Symfony для продакшен окружения
RUN php bin/console cache:clear --env=prod --no-debug
RUN php bin/console cache:warmup --env=prod --no-debug

# Опционально: выставляем права для папки var (если нужно)
RUN chmod -R 777 var

# Команда запуска (замени под своё приложение)
CMD ["php", "bin/console", "server:run", "0.0.0.0:8000"]
