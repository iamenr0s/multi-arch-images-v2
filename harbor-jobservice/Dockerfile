# syntax=docker/dockerfile:1.7

ARG HARBOR_REF=v2.15.0

#
# Stage 1: builder — cross-compile harbor_jobservice on the build host's native arch.
#
FROM golang:1.25.7 AS builder

ARG HARBOR_REF
ARG TARGETOS
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${HARBOR_REF}" https://github.com/goharbor/harbor.git .

# Mirrors the upstream compile_jobservice target: no swagger codegen needed
# (jobservice doesn't serve the v2 API directly), just `go build` with `-w -s`
# for a smaller binary.
ENV CGO_ENABLED=0
RUN set -eux; \
    cd src/jobservice; \
    GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
      go build -buildvcs=false \
        -ldflags "-w -s" \
        -o /out/harbor_jobservice .

RUN set -eux; \
    mkdir -p /out/assets; \
    cp make/photon/common/install_cert.sh    /out/assets/; \
    cp make/photon/jobservice/entrypoint.sh  /out/assets/

#
# Stage 2: runtime — photon:5.0, mirroring upstream harbor-jobservice-base layout.
#
FROM photon:5.0

ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="harbor-jobservice" \
      org.opencontainers.image.description="Harbor job service on Photon OS 5.0 (multi-arch rebuild of goharbor/harbor-jobservice)" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/goharbor/harbor" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

RUN tdnf install -y tzdata shadow ca-certificates >> /dev/null \
    && tdnf clean all \
    && groupadd --system --gid 10000 harbor \
    && useradd --system --uid 10000 --gid 10000 -d /harbor -s /sbin/nologin harbor \
    && mkdir -p /harbor /var/log/jobs \
    && chown -R harbor:harbor /var/log/jobs

WORKDIR /harbor

COPY --from=builder /out/harbor_jobservice       /harbor/harbor_jobservice
COPY --from=builder /out/assets/entrypoint.sh    /harbor/entrypoint.sh
COPY --from=builder /out/assets/install_cert.sh  /harbor/install_cert.sh

RUN chown -R harbor:harbor /etc/pki/tls/certs /harbor \
    && chmod u+x /harbor/entrypoint.sh /harbor/install_cert.sh /harbor/harbor_jobservice

VOLUME ["/var/log/jobs/"]

HEALTHCHECK CMD curl --fail -s http://localhost:8080/api/v1/stats \
        || curl -sk --fail \
              --key /etc/harbor/ssl/job_service.key \
              --cert /etc/harbor/ssl/job_service.crt \
              https://localhost:8443/api/v1/stats \
        || exit 1

USER harbor

ENTRYPOINT ["/harbor/entrypoint.sh"]
