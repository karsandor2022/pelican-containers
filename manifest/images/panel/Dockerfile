FROM --platform=$TARGETOS/$TARGETARCH docker.io/library/almalinux:10-minimal AS base

LABEL maintainer="Cameron Carney <ccarney@zyphi.co>"

# Allows the end user to customize what php modules and packages they want on buildtime
ENV PHP_VERSION=8.3
ENV PHP_MODULES=bcmath,cli,common,fpm,gd,gmp,intl,json,mbstring,mysql,opcache,zip,process,soap,sodium,xml,zstd,sqlite3
ENV TINI_VERSION=v0.19.0

# Create the Caddy group and user with ID 500
RUN microdnf install -y shadow-utils tzdata && \
    groupadd -r -g 500 caddy && \
    useradd -r -g caddy -u 500 -d /var/lib/caddy -s /sbin/nologin -c 'Caddy web server' caddy && \
    install -d -m 0750 -o caddy -g caddy /var/lib/caddy

# Install any required dependencies for the container to operate
RUN rpm --install https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm && \
    rpm --install https://rpms.remirepo.net/enterprise/remi-release-10.rpm && \
    curl -Lo /etc/yum.repos.d/caddy.repo https://copr.fedorainfracloud.org/coprs/g/caddy/caddy/repo/epel-10/group_caddy-caddy-epel-10.repo && \
    microdnf install -y python3 python3-pip  && \
    microdnf module enable -y php:remi-${PHP_VERSION} && \
    eval microdnf install -y ca-certificates caddy php-{$PHP_MODULES} &&\
    pip3 install yacron && \
    microdnf clean all && \
    pip3 cache purge


#Copy contents to root directory
COPY ./root/ /

# Export a persistent volume for caddy to store persistent data
VOLUME [ "/var/lib/caddy" ]

WORKDIR /var/www/html

# Let tini execute /entrypoint. This allows proper reaping of processes
#USER caddy
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod 777 /usr/bin/tini
RUN chmod -R 777 /entrypoint.sh
ENTRYPOINT [ "/usr/bin/tini", "--", "bash", "/entrypoint.sh" ]
CMD [ "start-web" ]

# Build phase of the container
# This is where composer is added and pelican properly setup
FROM base AS build

ARG VERSION
ARG GIT_BRANCH=release/${VERSION}

ENV VERSION=${VERSION}
ENV NODE_OPTIONS=--openssl-legacy-provider

#USER root

RUN \
    microdnf install -y findutils git yarnpkg

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
    yarn install --production && \
    yarn add cross-env && \
    yarn run && \
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
    
EXPOSE 80

VOLUME [ "/data" ]
