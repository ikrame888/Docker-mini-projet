# Dockerfile simple pour l'application web étudiante avec PHP
FROM nginx:alpine

LABEL org.opencontainers.image.authors="Ikrame Gouaiche <gouaicheikrame@gmail.com>"
LABEL org.opencontainers.image.description="Application web avec PHP pour gestion des étudiants"
LABEL org.opencontainers.image.version="1.0"

# Installation des outils nécessaires
RUN apk add --no-cache \
    php82 \
    php82-fpm \
    php82-curl \
    php82-json \
    supervisor \
    curl

# Configuration PHP-FPM pour fonctionner avec Nginx
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's/;listen.group = nobody/listen.group = nginx/g' /etc/php82/php-fpm.d/www.conf

# Copie des fichiers de configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copie de l'application web
COPY website/ /var/www/html/

# Configuration des permissions
RUN chown -R nginx:nginx /var/www/html && \
    chmod -R 755 /var/www/html && \
    mkdir -p /var/log/supervisor

# Exposition du port
EXPOSE 80

# Démarrage de Supervisor qui gère Nginx et PHP-FPM
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]