# syntax=docker/dockerfile:1.23

ARG HARBOR_REF=v2.15.0

#
# Stage 1: fetch — clone Harbor to pull the redis config and healthcheck script.
#
FROM --platform=$BUILDPLATFORM alpine:3.20 AS fetcher

ARG HARBOR_REF

RUN apk add --no-cache git
RUN git clone --depth 1 --branch "${HARBOR_REF}" https://github.com/goharbor/harbor.git /src

#
# Stage 2: runtime — photon:5.0 + redis from tdnf.
#
FROM --platform=$TARGETPLATFORM photon:5.0

ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="harbor-redis" \
      org.opencontainers.image.description="Harbor Redis on Photon OS 5.0 (multi-arch rebuild of goharbor/redis-photon)" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/goharbor/harbor" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

RUN tdnf install -y shadow >> /dev/null \
    && groupadd -g 999 redis \
    && useradd -u 999 -g 999 -c "Redis Database Server" -d /var/lib/redis -s /sbin/nologin -m redis \
    && tdnf install -y redis \
    && tdnf clean all

VOLUME /var/lib/redis
WORKDIR /var/lib/redis

COPY --from=fetcher /src/make/photon/redis/docker-healthcheck  /usr/bin/docker-healthcheck
COPY --from=fetcher /src/make/photon/redis/redis.conf          /etc/redis.conf

RUN chmod +x /usr/bin/docker-healthcheck \
    && chown redis:redis /etc/redis.conf

HEALTHCHECK CMD ["docker-healthcheck"]

USER redis

CMD ["redis-server", "/etc/redis.conf"]
