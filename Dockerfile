# ============================================================================
# particlekit/nextcloud - Debian 13 (trixie) + Nextcloud 35.0.2
#
# 2026-10-22: replaced the Alpine 3.17 / NC 25 build.
#   - Debian 13 (trixie)  = latest stable Debian
#   - Nextcloud 35.0.2    = current supported NC major
#   - PHP 8.5.12          = PATCHED for CVE-2026-109618 / CVE-2026-109619
#                            (from packages.sury.org; Debian's own php8.5 and
#                             the official nextcloud:35-apache image still ship
#                             the vulnerable 8.5.11)
#   - upstream's two mitigations applied as defence in depth
#   - our nc-install entrypoint + /tpl template mechanism preserved
#
# PHP minor per NC major (see lib/versioncheck.php bounds):
#   NC 26,27      -> PHP 8.2
#   NC 28,29,30   -> PHP 8.3
#   NC 31,32      -> PHP 8.4
#   NC 33,34,35   -> PHP 8.5
# ============================================================================
FROM debian:13

MAINTAINER martin@gabelmann.biz

ENV DEBIAN_FRONTEND=noninteractive \
    DB_TYPE=mysql \
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
    NC_SKELETON="/var/lib/nextcloud/skeleton" \
    NC_SSL_CERTIFICATE="/etc/ssl/apache2/server.pem" \
    NC_SSL_CHAIN="/etc/ssl/apache2/server.crt" \
    NC_SSL_KEY="/etc/ssl/apache2/server.key"

WORKDIR "$NC_WWW"

# PHP minor per NC major (see lib/versioncheck.php bounds):
#   NC 26,27      -> PHP 8.2   (sury 8.2.35, patched)
#   NC 28,29,30   -> PHP 8.3   (sury 8.3.36, patched)
#   NC 31,32      -> PHP 8.4   (sury 8.4.27, patched)
#   NC 33,34,35   -> PHP 8.5   (sury 8.5.12, patched)
ARG PHP_VERSION=8.5

# ---------------------------------------------------------------------------
# Base OS + PHP 8.5.12 from sury (the patched PHP)
#
# The sury repo must be added BEFORE any php${PHP_VERSION}-* package is installed
# (libapache2-mod-php${PHP_VERSION} only exists there, not in Debian's own archive).
# ---------------------------------------------------------------------------
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        bzip2 \
        unzip \
        apache2 \
        apache2-utils \
        tzdata \
        openssl \
        ldap-utils \
        libldap2 \
        gettext \
        coturn \
        apcupsd \
        imagemagick \
        graphicsmagick \
        libmemcached-dev \
        libmemcached11 \
        libicu-dev \
        libgpg-error0 \
        libzip-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libwebp-dev \
        libxpm-dev \
        libonig-dev \
        libxml2-dev \
        libpq-dev \
        libsqlite3-dev \
        libpspell-dev \
        libenchant-2-dev \
        libgmp-dev \
        libldap2-dev \
        libargon2-dev \
        libsodium-dev \
        libpcre2-dev \
    ; \
    # sury.org provides the patched PHP for Debian 13
    curl -fsSL https://packages.sury.org/php/apt.gpg -o /usr/share/keyrings/sury-php.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ trixie main" \
        > /etc/apt/sources.list.d/sury-php.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libapache2-mod-php${PHP_VERSION} \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-ldap \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-gmp \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-enchant \
        php${PHP_VERSION}-pspell \
        php${PHP_VERSION}-igbinary \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-memcached \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-apcu \
    ; \
    # MariaDB (Debian 13 = 11.8; production runs 10.6 - see report)
    apt-get install -y --no-install-recommends \
        mariadb-server \
        mariadb-client \
    ; \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Nextcloud 35.0.2 code (from the official image layout, but self-contained)
# ---------------------------------------------------------------------------
ARG NC_VERSION=35.0.2
RUN set -eux; \
    mkdir -p /usr/src/nextcloud; \
    curl -fsSL -o /tmp/nc.tar.bz2 \
        "https://download.nextcloud.com/server/releases/nextcloud-${NC_VERSION}.tar.bz2"; \
    tar -xjf /tmp/nc.tar.bz2 -C /usr/src/nextcloud --strip-components=1; \
    rm -f /tmp/nc.tar.bz2; \
    # NC 35 expects a 'config' dir next to the code
    mkdir -p /usr/src/nextcloud/config; \
    php -r 'require "/usr/src/nextcloud/version.php"; echo "NC code version: ".implode(".", $OC_Version)."\n";'

# ---------------------------------------------------------------------------
# PHP hardening:
#   CVE-2026-109618 (RCE via OOM corruption)  -> memory_limit=-1, low post_max_size
#   CVE-2026-109619 (RCE via stale global state) -> session.upload_progress.enabled=0
# These are upstream's documented mitigations and are applied IN ADDITION to
# the patched PHP, as defence in depth.
# ---------------------------------------------------------------------------
RUN set -eux; \
    INI=/etc/php/${PHP_VERSION}/apache2/php.ini; \
    CLI_INI=/etc/php/${PHP_VERSION}/cli/php.ini; \
    for f in "$INI" "$CLI_INI"; do \
        sed -i \
            -e 's|^memory_limit = .*|memory_limit = -1|' \
            -e 's|^post_max_size = .*|post_max_size = 8M|' \
            -e 's|^upload_max_filesize = .*|upload_max_filesize = 8M|' \
            "$f"; \
        printf 'session.upload_progress.enabled = 0\n' > /etc/php/${PHP_VERSION}/mods-available/99-nextcloud-cve.ini; \
    done; \
    install -m 0644 /etc/php/${PHP_VERSION}/mods-available/99-nextcloud-cve.ini /etc/php/${PHP_VERSION}/apache2/conf.d/99-nextcloud-cve.ini; \
    install -m 0644 /etc/php/${PHP_VERSION}/mods-available/99-nextcloud-cve.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-nextcloud-cve.ini; \
    rm -f /etc/php/${PHP_VERSION}/mods-available/99-nextcloud-cve.ini; \
    # apcu tuning (our production config.php uses memcache.local = APCu)
    printf 'apc.enabled=1\napc.shm_size=64M\napc.ttl=7200\napc.enable_cli=1\n' \
        > /etc/php/${PHP_VERSION}/mods-available/99-nextcloud-apcu.ini; \
    install -m 0644 /etc/php/${PHP_VERSION}/mods-available/99-nextcloud-apcu.ini /etc/php/${PHP_VERSION}/apache2/conf.d/99-nextcloud-apcu.ini; \
    install -m 0644 /etc/php/${PHP_VERSION}/mods-available/99-nextcloud-apcu.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-nextcloud-apcu.ini; \
    rm -f /etc/php/${PHP_VERSION}/mods-available/99-nextcloud-apcu.ini; \
    # opcache tuning (same values as the old alpine image)
    printf 'opcache.enable=1\nopcache.enable_cli=1\nopcache.max_accelerated_files=10000\nopcache.memory_consumption=128\nopcache.save_comments=1\nopcache.interned_strings_buffer=8\nopcache.revalidate_freq=1\n' \
        > /etc/php/${PHP_VERSION}/mods-available/99-nextcloud-opcache.ini; \
    install -m 0644 /etc/php/${PHP_VERSION}/mods-available/99-nextcloud-opcache.ini /etc/php/${PHP_VERSION}/apache2/conf.d/99-nextcloud-opcache.ini; \
    install -m 0644 /etc/php/${PHP_VERSION}/mods-available/99-nextcloud-opcache.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-nextcloud-opcache.ini; \
    rm -f /etc/php/${PHP_VERSION}/mods-available/99-nextcloud-opcache.ini

# ---------------------------------------------------------------------------
# Apache: keep the production layout AND the production UID/GID numbers.
#
# The production data dir (/srv/docker/nextcloud/data, 123 GB, 860k files) and
# the apps dir are owned by uid 100 / gid 101 (apache:apache on alpine).
# The new image must use the SAME numeric ids or it cannot read/write them.
#   apache = 100:101   (www-data is 33:33 on Debian, fine as-is)
#   mysql  = 102:103   (production mysqld runs as 102:103)
# ---------------------------------------------------------------------------
RUN set -eux; \
    # Debian packages squat on the uids/gids that PRODUCTION uses for apache
    # (100:101). Production's data dir and apps dir are owned by 100:101, so
    # the new image must keep apache = 100:101 and push the package-owned
    # accounts out of the way:
    #   production apache  = 100:101   (webroot, data, apps)
    #   production mysql   = 102:103   (datadir)
    #   debian turnserver  = 100:101  -> remap to 1101:1101
    #   debian mysql       = 101:102  -> remap to  102:103
    if getent group turnserver >/dev/null; then groupmod -g 1101 turnserver; fi; \
    if getent passwd turnserver >/dev/null; then usermod -u 1101 -g 1101 turnserver; fi; \
    if getent group mysql >/dev/null; then groupmod -g 103 mysql; fi; \
    if getent passwd mysql >/dev/null; then usermod -u 102 -g 103 mysql; fi; \
    # apache user/group with the production numeric ids (100:101)
    getent group apache >/dev/null || groupadd -g 101 apache; \
    id -u apache >/dev/null 2>&1 || useradd -u 100 -g 101 -m -s /bin/sh apache; \
    # sanity check: the ids must be unique and as intended
    test "$(getent group apache | cut -d: -f3)" = "101"; \
    test "$(id -u apache)" = "100"; \
    test "$(id -u mysql)" = "102"; \
    test "$(id -u turnserver)" = "1101"; \
    # webroot layout identical to production
    mkdir -p "$NC_WWW"; \
    rm -rf "$NC_WWW"; \
    ln -s /usr/src/nextcloud "$NC_WWW"; \
    ln -sf "$NC_WWW/occ" /usr/local/bin/occ; \
    chmod +x /usr/src/nextcloud/occ; \
    # apache config: use a single httpd.conf-driven setup like the alpine image
    a2enmod php${PHP_VERSION} 2>/dev/null || true; \
    a2enmod rewrite proxy proxy_http headers ssl socache_shmcb 2>/dev/null || true; \
    a2dissite 000-default 2>/dev/null || true; \
    a2enconf docker-php 2>/dev/null || true; \
    # apache2-foreground equivalent (the php:*-apache images ship this helper,
    # we build on plain debian so we provide our own). It must source
    # /etc/apache2/envvars, otherwise ${APACHE_RUN_DIR} etc. are undefined.
    printf '#!/bin/sh\nset -e\n. /etc/apache2/envvars\nexec apache2 -DFOREGROUND\n' > /usr/local/bin/apache2-foreground; \
    chmod +x /usr/local/bin/apache2-foreground; \
    # apache must run as our uid 100 user (production uses apache, not www-data)
    sed -i '/^export APACHE_RUN_USER=/d; /^export APACHE_RUN_GROUP=/d' /etc/apache2/envvars; \
    printf 'export APACHE_RUN_USER=apache\nexport APACHE_RUN_GROUP=apache\n' >> /etc/apache2/envvars; \
    sed -i 's/^\(User\|Group\) www-data/\1 apache/' /etc/apache2/apache2.conf 2>/dev/null || true; \
    # sanity: exactly one APACHE_RUN_USER, and it must be apache
    test "$(grep -c '^export APACHE_RUN_USER=' /etc/apache2/envvars)" = "1"; \
    grep -q '^export APACHE_RUN_USER=apache$' /etc/apache2/envvars; \
    # code owned by apache, like production
    mkdir -p /etc/nextcloud; \
    chown -R apache:apache /usr/src/nextcloud; \
    chown -R apache:apache /etc/nextcloud

# ---------------------------------------------------------------------------
# Our own tpl layer (config.php template + apache vhost) — same as the
# production /tpl, adapted to the Debian layout.
# ---------------------------------------------------------------------------
ADD nc-install /usr/local/bin/nc-install
ADD tpl /tpl
# ADD preserves the source file mode; make the entrypoint executable explicitly
RUN chmod 0755 /usr/local/bin/nc-install

VOLUME "/var/lib/nextcloud"
VOLUME "/var/lib/mysql"
VOLUME "/tpl"

EXPOSE 80 443

ENTRYPOINT ["nc-install"]
CMD ["apache2-foreground"]
