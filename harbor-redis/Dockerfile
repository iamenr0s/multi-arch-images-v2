# syntax=docker/dockerfile:1.25@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

ARG HARBOR_REF=v2.15.0

#
# Stage 1: fetch — clone Harbor to pull the valkey config and healthcheck script.
# (Upstream replaced Redis with Valkey in v2.15.2; make/photon/redis/ is now
# make/photon/valkey/.)
#
FROM docker.io/library/alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS fetcher

ARG HARBOR_REF

RUN apk add --no-cache git
RUN git clone --depth 1 --branch "${HARBOR_REF}" https://github.com/goharbor/harbor.git /src

#
# Stage 2: runtime — photon:5.0 + valkey from tdnf, mirroring upstream
# harbor-valkey-base.
#
FROM docker.io/library/photon:5.0@sha256:6db86de5ffc11d5c55e59d23790ad526b68e5bca4f030cb6a94e6136280866dd

ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="harbor-redis" \
      org.opencontainers.image.description="Harbor Valkey on Photon OS 5.0 (multi-arch rebuild of goharbor/valkey-photon)" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/goharbor/harbor" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

RUN tdnf install -y shadow >> /dev/null \
    && groupadd -g 999 valkey \
    && useradd -u 999 -g 999 -c "Valkey Database Server" -d /var/lib/redis -s /sbin/nologin -m valkey \
    && tdnf install -y valkey \
    && tdnf clean all

VOLUME /var/lib/redis
WORKDIR /var/lib/redis

COPY --from=fetcher /src/make/photon/valkey/docker-healthcheck  /usr/bin/docker-healthcheck
COPY --from=fetcher /src/make/photon/valkey/redis.conf          /etc/redis.conf

RUN chmod +x /usr/bin/docker-healthcheck \
    && chown valkey:valkey /etc/redis.conf

HEALTHCHECK CMD ["docker-healthcheck"]

USER valkey

CMD ["valkey-server", "/etc/redis.conf"]
