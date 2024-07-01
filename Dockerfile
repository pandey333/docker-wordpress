FROM wordpress:latest
# Example: Install and configure WordPress plugins, themes, etc.
COPY plugins /var/www/html/wp-content/plugins/
ENV WORDPRESS_DB_HOST=${DB_HOST}
ENV WORDPRESS_DB_NAME=${DB_NAME}
ENV WORDPRESS_DB_USER=${DB_USER}
ENV WORDPRESS_DB_PASSWORD=${DB_PASSWORD}
EXPOSE 80