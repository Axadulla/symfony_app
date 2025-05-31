# Используем официальный образ PHP с необходимыми расширениями
FROM php:8.2-cli

# Устанавливаем зависимости для Symfony и composer
RUN apt-get update && apt-get install -y \
    git unzip zip libicu-dev libonig-dev libxml2-dev \
    && docker-php-ext-install intl pdo pdo_mysql mbstring xml opcache

# Устанавливаем Composer глобально
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Создаем рабочую директорию
WORKDIR /app

# Копируем composer файлы (можно оставить, если хочешь кешировать зависимости)
COPY composer.json composer.lock ./

# Создаем пользователя appuser с домашней директорией
RUN useradd -m appuser

# Копируем весь исходный код **сразу после composer.json**
COPY --chown=appuser:appuser . .

# Даем права на рабочую директорию appuser
RUN chown -R appuser:appuser /app

# Переключаемся на пользователя appuser
USER appuser

# Устанавливаем зависимости composer без dev и с оптимизацией автозагрузчика
RUN composer install --no-dev --optimize-autoloader

# Предварительно очищаем и греем кэш Symfony для prod окружения
RUN php bin/console cache:clear --env=prod --no-debug
RUN php bin/console cache:warmup --env=prod --no-debug

# Опционально: выставляем права на var папку
RUN chmod -R 777 var

# Запускаем приложение (замени на свой CMD или ENTRYPOINT)
CMD ["php", "bin/console", "server:run", "0.0.0.0:8000"]
