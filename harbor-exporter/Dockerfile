# syntax=docker/dockerfile:1.7

ARG HARBOR_REF=v2.15.0

#
# Stage 1: builder — cross-compile harbor_exporter on the build host's native arch.
# Upstream's Dockerfile hardcodes GOARCH=amd64; we override via TARGETARCH for
# multi-arch support.
#
FROM --platform=$BUILDPLATFORM golang:1.25.7 AS builder

ARG HARBOR_REF
ARG TARGETOS
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${HARBOR_REF}" https://github.com/goharbor/harbor.git .

ENV CGO_ENABLED=0
RUN set -eux; \
    RELEASEVERSION="$(cat VERSION)"; \
    GITCOMMIT="$(git rev-parse --short=8 HEAD)"; \
    cd src/cmd/exporter; \
    GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
      go build \
        -ldflags "-w -s \
          -X github.com/goharbor/harbor/src/pkg/version.ReleaseVersion=${RELEASEVERSION} \
          -X github.com/goharbor/harbor/src/pkg/version.GitCommit=${GITCOMMIT}" \
        -o /out/harbor_exporter .

RUN set -eux; \
    mkdir -p /out/assets; \
    cp make/photon/common/install_cert.sh   /out/assets/; \
    cp make/photon/exporter/entrypoint.sh   /out/assets/

#
# Stage 2: runtime — photon:5.0, mirroring upstream harbor-exporter-base.
#
FROM --platform=$TARGETPLATFORM photon:5.0

ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="harbor-exporter" \
      org.opencontainers.image.description="Harbor Prometheus exporter on Photon OS 5.0 (multi-arch rebuild of goharbor/harbor-exporter)" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/goharbor/harbor" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

RUN tdnf install -y tzdata shadow ca-certificates >> /dev/null \
    && tdnf clean all \
    && groupadd --system --gid 10000 harbor \
    && useradd --system --uid 10000 --gid 10000 -d /harbor -s /sbin/nologin harbor \
    && mkdir -p /harbor

WORKDIR /harbor

COPY --from=builder /out/harbor_exporter         /harbor/harbor_exporter
COPY --from=builder /out/assets/entrypoint.sh    /harbor/entrypoint.sh
COPY --from=builder /out/assets/install_cert.sh  /harbor/install_cert.sh

RUN chown -R harbor:harbor /etc/pki/tls/certs /harbor \
    && chmod u+x /harbor/entrypoint.sh /harbor/install_cert.sh /harbor/harbor_exporter

USER harbor

ENTRYPOINT ["/harbor/entrypoint.sh"]
