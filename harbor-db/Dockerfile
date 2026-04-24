# syntax=docker/dockerfile:1.7

ARG HARBOR_REF=v2.15.0

#
# Stage 1: fetch — clone Harbor to pull the db/* scripts. No compilation needed,
# so use a tiny image on BUILDPLATFORM.
#
FROM --platform=$BUILDPLATFORM alpine:3.20 AS fetcher

ARG HARBOR_REF

RUN apk add --no-cache git
RUN git clone --depth 1 --branch "${HARBOR_REF}" https://github.com/goharbor/harbor.git /src

#
# Stage 2: runtime — photon:5.0 with Postgres 14 *and* 15 installed. Harbor's
# upgrade.sh uses both to migrate data across major versions on first boot.
#
FROM --platform=$TARGETPLATFORM photon:5.0

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

RUN tdnf install -y shadow >> /dev/null \
    && groupadd -r -g 999 postgres \
    && useradd --no-log-init -r -g 999 -u 999 -d /var/lib/postgresql -s /sbin/nologin postgres \
    && tdnf install -y postgresql14-server postgresql14 postgresql15-server postgresql15 \
         gzip findutils bc util-linux net-tools >> /dev/null \
    && tdnf clean all \
    && mkdir -p /var/run/postgresql /var/lib/postgresql /docker-entrypoint-initdb.d "${PGDATA}" \
    && chown -R postgres:postgres /var/run/postgresql /var/lib/postgresql /docker-entrypoint-initdb.d "${PGDATA}" \
    && chmod 2777 /var/run/postgresql \
    && sed -i "s|^#listen_addresses = 'localhost'|listen_addresses = '*'|" \
         /usr/share/postgresql/15/postgresql.conf.sample \
    && sed -i "s|^#unix_socket_directories = '/run/postgresql'|unix_socket_directories = '/run/postgresql'|" \
         /usr/share/postgresql/15/postgresql.conf.sample

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
