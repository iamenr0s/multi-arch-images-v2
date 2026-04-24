# syntax=docker/dockerfile:1.7

ARG HARBOR_REF=v2.15.0

#
# Stage 1: fetch — clone Harbor to pull the rsyslog configs and start script.
#
FROM --platform=$BUILDPLATFORM alpine:3.20 AS fetcher

ARG HARBOR_REF

RUN apk add --no-cache git
RUN git clone --depth 1 --branch "${HARBOR_REF}" https://github.com/goharbor/harbor.git /src

#
# Stage 2: runtime — photon:5.0 with cronie + rsyslog + logrotate. This
# container aggregates logs from the other Harbor components.
#
FROM --platform=$TARGETPLATFORM photon:5.0

ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="harbor-log" \
      org.opencontainers.image.description="Harbor log aggregator (rsyslog + logrotate) on Photon OS 5.0 (multi-arch rebuild of goharbor/harbor-log)" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/goharbor/harbor" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

RUN tdnf install -y cronie rsyslog logrotate shadow tar gzip sudo net-tools >> /dev/null \
    && groupadd -g 10000 syslog \
    && useradd -u 10000 -g 10000 -s /sbin/nologin -m syslog \
    && mkdir -p /var/spool/rsyslog \
    && tdnf clean all \
    && chage -M 99999 root

COPY --from=fetcher /src/make/photon/log/rsyslog.conf         /etc/rsyslog.conf
COPY --from=fetcher /src/make/photon/log/rsyslog_docker.conf  /etc/rsyslog.d/rsyslog_docker.conf

# Move logrotate out of the daily cron to run hourly instead (matches upstream).
RUN rm -f /etc/cron.daily/logrotate
COPY --from=fetcher /src/make/photon/log/logrotate  /etc/cron.hourly/logrotate

COPY --from=fetcher /src/make/photon/log/start.sh   /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh /etc/cron.hourly/logrotate \
    && chmod +x /etc/rsyslog.d/ || true \
    && chown -R 10000:10000 /etc/rsyslog.conf /etc/rsyslog.d/ /run /var/lib/logrotate/ /var/spool/rsyslog

HEALTHCHECK CMD netstat -ltun | grep 10514

VOLUME /var/log/docker/ /run/ /etc/logrotate.d/

CMD ["/usr/local/bin/start.sh"]
