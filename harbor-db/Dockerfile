# syntax=docker/dockerfile:1.23

ARG HARBOR_REF=v2.15.0

#
# Stage 1: fetch — clone Harbor to pull the db/* scripts. No compilation needed,
# so use a tiny image on BUILDPLATFORM.
#
FROM alpine:3.20 AS fetcher

ARG HARBOR_REF

RUN apk add --no-cache git
RUN git clone --depth 1 --branch "${HARBOR_REF}" https://github.com/goharbor/harbor.git /src

#
# Stage 2: runtime — photon:5.0 with Postgres 14 *and* 15 installed. Harbor's
# upgrade.sh uses both to migrate data across major versions on first boot.
#
FROM photon:5.0

ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="harbor-db" \
      org.opencontainers.image.description="Harbor PostgreSQL 14/15 database on Photon OS 5.0 (multi-arch rebuild of goharbor/harbor-db)" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/goharbor/harbor" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

ENV PGDATA=/var/lib/postgresql/data

# Mirrors upstream harbor-db-base layout exactly. Photon ships toybox by default,
# which conflicts with util-linux/net-tools and must be removed first.
# postgresql.conf.sample lives at /usr/pgsql/<major>/share/postgresql/ on Photon
# (not the Debian-style /usr/share/postgresql/<major>/ path).
RUN tdnf install -y shadow >> /dev/null \
    && groupadd -r postgres --gid=999 \
    && useradd -m -r -g postgres --uid=999 postgres \
    && tdnf install -y postgresql14-server >> /dev/null \
    && tdnf install -y gzip postgresql15-server findutils bc >> /dev/null \
    && mkdir -p /docker-entrypoint-initdb.d /run/postgresql "${PGDATA}" \
    && chown -R postgres:postgres /run/postgresql "${PGDATA}" \
    && chmod 2777 /run/postgresql \
    && chmod 777 "${PGDATA}" \
    && sed -i "s|#listen_addresses = 'localhost'.*|listen_addresses = '*'|g" \
         /usr/pgsql/15/share/postgresql/postgresql.conf.sample \
    && sed -i "s|#unix_socket_directories = '/tmp'.*|unix_socket_directories = '/run/postgresql'|g" \
         /usr/pgsql/15/share/postgresql/postgresql.conf.sample \
    && tdnf clean all \
    && tdnf erase -y toybox \
    && tdnf install -y util-linux net-tools

VOLUME /var/lib/postgresql/data

COPY --from=fetcher /src/make/photon/db/docker-entrypoint.sh    /docker-entrypoint.sh
COPY --from=fetcher /src/make/photon/db/initdb.sh               /initdb.sh
COPY --from=fetcher /src/make/photon/db/upgrade.sh              /upgrade.sh
COPY --from=fetcher /src/make/photon/db/docker-healthcheck.sh   /docker-healthcheck.sh
COPY --from=fetcher /src/make/photon/db/initial-registry.sql    /docker-entrypoint-initdb.d/

RUN chown -R postgres:postgres \
        /docker-entrypoint.sh /initdb.sh /upgrade.sh \
        /docker-healthcheck.sh /docker-entrypoint-initdb.d \
    && chmod u+x /docker-entrypoint.sh /initdb.sh /upgrade.sh /docker-healthcheck.sh

USER postgres

ENTRYPOINT ["/docker-entrypoint.sh", "14", "15"]

HEALTHCHECK CMD ["/docker-healthcheck.sh"]
