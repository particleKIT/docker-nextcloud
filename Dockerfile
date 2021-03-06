FROM alpine
MAINTAINER martin@gabelmann.biz

ENV DB_TYPE=mysql \
    DB_HOST=localhost \
    DB_NAME=nextcloud_db \
    DB_USER=nextcloud \
    DB_PASS=changemepls \
    DB_ROOT_PASS=changemepls \
    DB_PREFIX="" \
    DB_DATA_PATH=/var/lib/mysql \
    DB_MAX_ALLOWED_PACKET="200M" \
    DB_EXTERNAL=false \
    NC_ADMIN=admin \
    NC_EMAIL="admin@localhost" \
    NC_ADMINPASS=changemepls \
    NC_DATADIR=/var/lib/nextcloud/data \
    NC_FIXDATADIR="no" \
    NC_WWW=/var/www/localhost/htdocs \
    NC_DOMAIN=localhost \
    NC_TIME="Europe/Berlin" \
    NC_LC="en_US.UTF-8" \
    NC_TRUSTED_DOMAINS="'localhost','127.0.0.1'," \
    NC_LANGUAGE=en \
    NC_DEFAULTAPP=files \
    NC_OVERWRITEHOST="" \
    NC_LOGLEVEL=1 \
    NC_MAIL_FROM_ADDRESS=admin \
    NC_MAIL_SMTPMODE=smtp \
    NC_MAIL_DOMAIN=localhost \
    NC_MAIL_SMTPAUTHTYPE=LOGIN \
    NC_MAIL_SMTPAUTH=1 \
    NC_MAIL_SMTPHOST='smtp.localhost' \
    NC_MAIL_SMTPPORT=465 \
    NC_MAIL_SMTPNAME=admin@localhost \
    NC_MAIL_SMTPSECURE=ssl \
    NC_MAIL_SMTPPASSWORD=changemepls \
    NC_SKELETON="/var/www/localhost/htdocs/core/skeleton" \
    NC_SSL_CERTIFICATE="/etc/ssl/apache2/server.pem" \
    NC_SSL_CHAIN="/etc/ssl/apache2/server.pem" \
    NC_SSL_KEY="/etc/ssl/apache2/server.key"


WORKDIR "$NC_WWW"
   
RUN apk update && apk upgrade &&\
    apk add mariadb mariadb-client tzdata openssl openldap-clients ca-certificates apache2 apache2-ssl apache2-proxy \
            gettext php7 php7-apache2 php7-gd php7-memcached php7-imagick php7-bz2 php7-posix \
            php7-json php7-pdo_mysql php7-mcrypt php7-intl php7-apcu php7-openssl php7-fileinfo \
            php7-curl php7-zip php7-mbstring php7-dom php7-xmlreader php7-ctype php7-zlib apcupsd \
            php7-iconv php7-xmlrpc php7-simplexml php7-xmlwriter php7-pcntl php7-ldap php7-opcache libexif php7-exif php7-gmp php7-bcmath \ 
            nextcloud-mysql php7-ldap nextcloud-activity nextcloud-admin_audit nextcloud-comments nextcloud-doc nextcloud-encryption \
            nextcloud-federation nextcloud-files_external nextcloud-files_pdfviewer nextcloud-files_sharing nextcloud-privacy nextcloud-recommendations \
            nextcloud-files_trashbin nextcloud-files_versions nextcloud-files_videoplayer nextcloud-firstrunwizard nextcloud-gallery \
            nextcloud-initscript nextcloud-logreader nextcloud-mysql nextcloud-nextcloud_announcements nextcloud-notifications nextcloud-default-apps \
            nextcloud-password_policy nextcloud-pgsql nextcloud-serverinfo nextcloud-sharebymail nextcloud-survey_client nextcloud-systemtags\
            nextcloud-support nextcloud-cloud_federation_api nextcloud-accessibility nextcloud-theming nextcloud-user_ldap coturn &&\
    /usr/bin/install -g apache -m 775  -d /run/apache2 &&\
    /usr/bin/install -g mysql -m 775  -d /run/mysqld &&\
    chmod o+rwx,g+rwx,u+rwx /var/tmp/ &&\
    mv /etc/apache2/conf.d/ssl.conf /etc/apache2/conf.d/ssl.conf.bak &&\
    mv /etc/apache2/conf.d/userdir.conf /etc/apache2/conf.d/userdir.conf.bak &&\
    rm -rf $NC_WWW &&\
    ln -s /usr/share/webapps/nextcloud $NC_WWW &&\
    rm -f $NC_WWW/core/doc &&\ 
    mv /usr/share/doc/nextcloud/core/ $NC_WWW/core/doc &&\
    rm -f /usr/share/webapps/nextcloud/resources/config/ca-bundle.crt &&\
    cp /etc/ssl/certs/ca-certificates.crt /usr/share/webapps/nextcloud/resources/config/ca-bundle.crt &&\  
    chown -R apache:apache $NC_WWW &&\
    echo "LoadModule proxy_module modules/mod_proxy.so" > /etc/apache2/conf.d/proxy.conf &&\
    echo "LoadModule proxy_http_module modules/mod_proxy_http.so" >> /etc/apache2/conf.d/proxy.conf &&\
    echo "LoadModule proxy_wstunnel_module modules/mod_proxy_wstunnel.so" >> /etc/apache2/conf.d/proxy.conf &&\
    sed -i '/proxy_module/s/^#//g' /etc/apache2/httpd.conf &&\
    sed -i '/proxy_connect_module/s/^#//g' /etc/apache2/httpd.conf &&\
    sed -i '/proxy_ftp_module/s/^#//g' /etc/apache2/httpd.conf &&\
    sed -i '/proxy_http_module/s/^#//g' /etc/apache2/httpd.conf &&\
    sed -i '/proxy_wstunnel_module/s/^#//g' /etc/apache2/httpd.conf &&\
    sed -i '/proxy_ajp_module/s/^#//g' /etc/apache2/httpd.conf &&\
    sed -i '/proxy_balancer_module/s/^#//g' /etc/apache2/httpd.conf &&\
    sed -i '/ssl_module/s/^#//g' /etc/apache2/httpd.conf &&\
    sed -i '/cgi_module/s/^#//g' /etc/apache2/httpd.conf &&\
    sed -i '/mpm_prefork_module/s/^#//g' /etc/apache2/httpd.conf &&\
    sed -i '/mpm_event_module/s/^/#/g' /etc/apache2/httpd.conf &&\
    sed -i '/rewrite_module/s/^#//g' /etc/apache2/httpd.conf &&\
    sed -i 's/^;open_basedir.*$/open_basedir=\/var\/lib\/nextcloud:\/usr\/share\/webapps\/nextcloud:\/etc\/nextcloud:\/var\/www\/localhost\/htdocs:\/tmp\/:\/dev\/urandom/' /etc/php7/php.ini &&\
    echo -e 'extension=apcu.so' > /etc/php7/conf.d/apcu.ini &&\
    echo -e 'apc.enabled=1\napc.shm_size=64M\napc.ttl=7200\napc.enable_cli=1' >> /etc/php7/conf.d/apcu.ini &&\
    echo -e 'opcache.enable=1\nopcache.enable_cli=1\n' >> /etc/php7/conf.d/00_opcache.ini &&\
    echo -e 'opcache.max_accelerated_files=10000\n' >> /etc/php7/conf.d/00_opcache.ini &&\
    echo -e 'opcache.memory_consumption=128\nopcache.save_comments=1\n' >> /etc/php7/conf.d/00_opcache.ini &&\
    echo -e 'opcache.interned_strings_buffer=8\nopcache.revalidate_freq=1' >> /etc/php7/conf.d/00_opcache.ini &&\
    sed -i 's/^upload_max_filesize.*$/upload_max_filesize=1512M/' /etc/php7/php.ini &&\
    sed -i 's/^memory_limit.*$/memory_limit=2512M/' /etc/php7/php.ini &&\
    ln -s /var/www/localhost/htdocs/occ /usr/local/bin/occ &&\
    chmod +x /usr/share/webapps/nextcloud/occ &&\
    rm -f /etc/nextcloud/config.php


ADD nc-install /usr/local/bin/nc-install
ADD tpl /tpl

VOLUME "/var/lib/nextcloud"
VOLUME "/var/lib/mysql"
VOLUME "/tpl"

EXPOSE 80 443

ENTRYPOINT ["nc-install"]
CMD ["/usr/sbin/httpd", "-kstart",  "-DFOREGROUND"] 
