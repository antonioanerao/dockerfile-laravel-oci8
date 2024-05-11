FROM nginx

VOLUME [ "/laravel" ]
WORKDIR /laravel
ENV ACCEPT_EULA=Y
ENV LD_LIBRARY_PATH=/usr/lib/oracle/21.1/client64/lib:$LD_LIBRARY_PATH
ENV ORACLE_HOME=/usr/lib/oracle/21.1/client64/lib

# Define a timezone padrão
RUN ln -fs /usr/share/zoneinfo/America/Rio_Branco /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Instala as dependências do sistema
RUN apt update && \
    apt -y upgrade && \
    echo "pt_BR.UTF-8 UTF-8" > /etc/locale.gen && \
    apt install -y ca-certificates \
                   apt-transport-https \
                   lsb-release \
                   gnupg \
                   curl \
                   wget \
                   vim \
                   dirmngr \
                   software-properties-common \
                   rsync \
                   gettext \
                   locales \
                   gcc \
                   g++ \
                   make \
                   unzip \
                   gcc \
                   g++ \
                   autoconf \
                   libc-dev \
                   pkg-config

# Define a localização padrão
RUN locale-gen

# Instala o PHP 8.2, suas extensões, node, npm e composer
RUN apt -y update && \
    apt -y install --allow-unauthenticated php8.2 \
                   php8.2-fpm \
                   php8.2-mysql \
                   php8.2-mbstring \
                   php8.2-soap \
                   php8.2-gd \
                   php8.2-xml \
                   php8.2-intl \
                   php8.2-dev \
                   php8.2-curl \
                   php8.2-zip \
                   php8.2-imagick \
                   php8.2-gmp \
                   php8.2-ldap \
                   php8.2-bcmath \
                   php8.2-bz2 \
                   php8.2-phar \
                   php8.2-sqlite3 && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer &&  \
    curl -s https://deb.nodesource.com/setup_18.x | bash && \
    apt-get update && \
    apt install nodejs -y 

# Instalação do Oracle Instant Client
RUN apt update && apt install -y libaio1 && mkdir -p /opt/oracle && cd /opt/oracle && \
    mkdir -p /usr/lib/oracle/21.1/client64 && \
    wget https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basic-linux.x64-21.1.0.0.0.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-sdk-linux.x64-21.1.0.0.0.zip && \
    unzip instantclient-basic-linux.x64-21.1.0.0.0.zip && \
    unzip instantclient-sdk-linux.x64-21.1.0.0.0.zip && \
    rm -f instantclient-basic-linux.x64-21.1.0.0.0.zip instantclient-sdk-linux.x64-21.1.0.0.0.zip && \
    ln -s /opt/oracle/instantclient_21_1 /usr/lib/oracle/21.1/client64/lib && \
    cd /usr/lib/oracle/21.1/client64 && \
    cp -r lib/sdk . && \
    echo "instantclient,/usr/lib/oracle/21.1/client64/lib" | pecl install oci8 && \
    echo "extension=oci8.so" > /etc/php/8.2/mods-available/oci8.ini && \
    phpenmod -v 8.2 oci8 && \
    cd /laravel && \
    composer create-project laravel/laravel . && \
    chgrp -R www-data /laravel/storage /laravel/bootstrap/cache /laravel/storage/logs && \
    chmod -R ug+rwx /laravel/storage /laravel/bootstrap/cache /laravel/storage/logs && \
    chown root:www-data -R database && chmod ug+rwx -R database

COPY config_cntr/php.ini /etc/php/8.2/fpm/php.ini
COPY config_cntr/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY config_cntr/nginx.conf /etc/nginx
COPY config_cntr/default.conf /etc/nginx/conf.d
