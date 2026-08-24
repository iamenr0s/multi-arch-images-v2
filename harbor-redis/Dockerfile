# syntax=docker/dockerfile:1.26@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32

# Must be >= v2.15.2: the valkey paths below don't exist in earlier tags.
ARG HARBOR_REF=v2.15.2

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
FROM docker.io/library/photon:5.0@sha256:ab4b68e15c8ff6b9c79ba525f696260f772c711761d576dd53bf43c351c9a504

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
