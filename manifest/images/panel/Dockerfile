FROM --platform=$TARGETOS/$TARGETARCH docker.io/library/almalinux:9-minimal AS sqlite-build

ARG SQLITE_VERSION=3530100
ARG SQLITE_YEAR=2026

RUN microdnf install -y gcc make tar gzip && \
    microdnf swap -y curl-minimal curl

RUN curl -Lo /tmp/sqlite.tar.gz \
        "https://www.sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_VERSION}.tar.gz" && \
    mkdir -p /tmp/sqlite-src && \
    tar xzf /tmp/sqlite.tar.gz -C /tmp/sqlite-src --strip-components=1 && \
    cd /tmp/sqlite-src && \
    CFLAGS="-DSQLITE_ENABLE_FTS5 \
            -DSQLITE_ENABLE_RTREE \
            -DSQLITE_ENABLE_GEOPOLY \
            -DSQLITE_ENABLE_COLUMN_METADATA \
            -DSQLITE_ENABLE_UPDATE_DELETE_LIMIT \
            -DSQLITE_ENABLE_MATH_FUNCTIONS \
            -DSQLITE_ENABLE_LOAD_EXTENSION" \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/sqlite.tar.gz /tmp/sqlite-src


FROM --platform=$TARGETOS/$TARGETARCH docker.io/library/almalinux:9-minimal AS base

LABEL maintainer="Cameron Carney <ccarney@zyphi.co>"

# Allows the end user to customize what php modules and packages they want on buildtime
ENV PHP_VERSION=8.5
ENV PHP_MODULES=bcmath,cli,common,curl,fpm,gd,intl,mbstring,mysqlnd,opcache,pdo,pdo_sqlite,sqlite3,xml,zip
ENV EXTRA_PACKAGES="nmap-ncat mariadb unzip"

# Create the Caddy group and user with ID 500
RUN microdnf install -y shadow-utils tzdata && \
    groupadd -r -g 500 caddy && \
    useradd -r -g caddy -u 500 -d /var/lib/caddy -s /sbin/nologin -c 'Caddy web server' caddy && \
    install -d -m 0750 -o caddy -g caddy /var/lib/caddy

# Install any required dependencies for the container to operate
RUN rpm --install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    rpm --install https://rpms.remirepo.net/enterprise/remi-release-9.rpm && \
    curl -Lo /etc/yum.repos.d/caddy.repo https://copr.fedorainfracloud.org/coprs/g/caddy/caddy/repo/epel-9/group_caddy-caddy-epel-9.repo && \
    microdnf module enable -y php:remi-${PHP_VERSION} nodejs:22 && \
    eval microdnf install -y ca-certificates caddy php-{$PHP_MODULES} \
        python3 python3-pip tini ${EXTRA_PACKAGES} && \
    pip3 install yacron && \
    microdnf clean all && \
    pip3 cache purge

# Replace system SQLite with the version built from source
COPY --from=sqlite-build /usr/local/bin/sqlite3 /usr/local/bin/sqlite3
COPY --from=sqlite-build /usr/local/include/sqlite3.h /usr/local/include/sqlite3.h
COPY --from=sqlite-build /usr/local/include/sqlite3ext.h /usr/local/include/sqlite3ext.h
COPY --from=sqlite-build /usr/local/lib/ /tmp/sqlite-lib/
RUN cp -P /tmp/sqlite-lib/libsqlite3.so* /usr/local/lib/ && \
    cp /tmp/sqlite-lib/libsqlite3.a /usr/local/lib/ && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/00-local.conf && \
    ldconfig && \
    rm -rf /tmp/sqlite-lib

# Copy contents to root directory
COPY ./root/ /

# Export a persistent volume for caddy to store persistent data
VOLUME [ "/var/lib/caddy" ]

WORKDIR /var/www/html

# Let tini execute /entrypoint. This allows proper reaping of processes
#USER caddy
ENTRYPOINT [ "/usr/bin/tini", "--", "/entrypoint.sh" ]
CMD [ "start-web" ]

# Build phase of the container
# This is where composer is added and pterodactyl properly setup
FROM base AS build

ARG VERSION
ARG GIT_BRANCH=release/${VERSION}

ENV VERSION=${VERSION}

#USER root

RUN \
    microdnf install -y findutils git nodejs

RUN \
    git clone https://github.com/pelican-dev/panel ./ --depth 1 --branch ${GIT_BRANCH} && \
    rm .git -rf && \
    chmod -R 755 storage/* bootstrap/cache && \
    find storage -type d > .storage.tmpl && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    cp .env.example .env && \
    composer install --ansi --no-dev --optimize-autoloader && \
    chown -R caddy:caddy *;

RUN \
    npm install && \
    npm run build && \
    rm -rf node_modules

# Remove persistent data folders as they will be symlinked further down
RUN rm .env ./storage -rf

# Final Production phase of the controller
# All build requirements get scrapped as to maintain a small image
FROM base AS production

ARG VERSION
ENV VERSION=${VERSION}

COPY --from=build --chown=caddy:caddy /var/www /var/www

# Symlink storage, config and cache to /data
RUN \
    ln -s /data/storage storage; \
    ln -s /data/pelican.conf .env;

VOLUME [ "/data" ]
