FROM golang:1.23.7-alpine AS build

ARG VERSION
ENV VERSION=${VERSION}
ARG GIT_BRANCH=release/${VERSION}

RUN \
  apk add git; \
  cd /; \
  git clone https://github.com/pelican-dev/wings --depth 1 --branch ${GIT_BRANCH}; \
  cd wings; \
  go build -ldflags="-s -w" -v trimpath;

FROM alpine:latest AS final

LABEL maintainer="Cameron Carney <ccarney16@live.com>"

ARG VERSION
ENV VERSION=${VERSION}

ENV WINGS_USERNAME=pelican
ENV WINGS_UID=100
ENV WINGS_GID=101

RUN \
  apk add --no-cache ca-certificates tini tzdata \
  && mkdir -p /etc/pelican /var/log/pelican /tmp/pelican \
  && echo "ID=\"distroless\"" > /etc/os-release


# Copy wings from build stage
COPY --from=build /wings/wings /usr/local/bin
COPY ./root /

EXPOSE 8080
EXPOSE 2022

# Default Work Directory
WORKDIR /var/lib/pelican

RUN chmod 755 /entrypoint.sh
ENTRYPOINT [ "tini", "--", "/entrypoint.sh" ]
