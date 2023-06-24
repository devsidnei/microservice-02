#!/bin/bash

# Verificar se a variável APP_ID existe no arquivo .env
env_file=".env"
app_id=$(grep -E "^APP_ID=" "$env_file" | cut -d '=' -f2 | tr -d '"')

# Verificar se a variável APP_ID existe
if [ -z "$app_id" ]; then
    echo -e "\e[31mA variável APP_ID não está definida no arquivo .env. Encerrando o script.\e[0m"
    exit 1
fi

# Verificar se o arquivo docker-compose.yml já existe
docker_compose_file="docker-compose.yml"
if [ -f "$docker_compose_file" ]; then
    echo -e "\e[31mO arquivo $docker_compose_file já existe. Encerrando o script.\e[0m"
    exit 1
fi

# Verificar se o arquivo nginx.conf já existe
nginx_conf="docker-compose/nginx/nginx.conf"
if [ -f "$nginx_conf" ]; then
    echo -e "\e[31mO arquivo $nginx_conf já existe. Encerrando o script.\e[0m"
    exit 1
fi

# Criar o conteúdo do arquivo nginx.conf substituindo a variável
echo "server {
    listen 80;
    index index.php;
    root /var/www/public;

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass microservice-${app_id}-app:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
        gzip_static on;
    }

    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
}" > "$nginx_conf"

echo -e "\e[32mArquivo $nginx_conf criado com sucesso!\e[0m"

# Criar o arquivo docker-compose.yml
echo "version: \"3.8\"

services:
  # application
  microservice-${app_id}-app:
    container_name: microservice-${app_id}-app
    image: devsidnei/php8.1-fpm
    working_dir: /var/www/
    volumes:
      - ./:/var/www/
    restart: unless-stopped
    extra_hosts:
      - host.docker.internal:host-gateway
    depends_on:
      - microservice-${app_id}-redis
    networks:
      - microservice-${app_id}

  #queue  
  microservice-${app_id}-queue:
    container_name: microservice-${app_id}-queue
    image: devsidnei/php8.1-fpm
    working_dir: /var/www/
    volumes:
      - ./:/var/www/
    restart: unless-stopped
    extra_hosts:
      - host.docker.internal:host-gateway
    depends_on:
      - microservice-${app_id}-redis
      - microservice-${app_id}-mariadb
    networks:
      - microservice-${app_id}

  #nginx  
  microservice-${app_id}-nginx:
    container_name: microservice-${app_id}-nginx
    image: nginx:alpine
    restart: unless-stopped
    expose:
      - 80
      - 443
    volumes:
      - ./docker-compose/nginx/:/etc/nginx/conf.d/
      - ./:/var/www
    networks:
      - microservice-${app_id}

  # redis  
  microservice-${app_id}-redis:
    container_name: microservice-${app_id}-redis
    image: redis:latest
    restart: unless-stopped
    networks:
      - microservice-${app_id}

  # mariadb  
  microservice-${app_id}-mariadb:
    container_name: microservice-${app_id}-mariadb
    image: mariadb:10.6.10
    restart: unless-stopped
    ports:
      - \${DB_PORT}:\${DB_PORT}
    volumes:
      - ./.docker/mysql/dbdata:/var/lib/mysql
    environment:
      MYSQL_DATABASE: \${DB_DATABASE}
      MYSQL_ROOT_PASSWORD: \${DB_PASSWORD}
      MYSQL_USER: \${DB_USERNAME}
      MYSQL_PASSWORD: \${DB_PASSWORD}
      MYSQL_TCP_PORT: \${DB_PORT}
    networks:
      - microservice-${app_id}

networks:
  microservice-${app_id}:
    name: microservice-${app_id}" > "$docker_compose_file"

echo -e "\e[32mArquivo $docker_compose_file criado com sucesso!\e[0m"
