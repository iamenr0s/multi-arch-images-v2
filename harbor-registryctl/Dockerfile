# syntax=docker/dockerfile:1.7

ARG HARBOR_REF=v2.15.0
ARG REGISTRY_SRC_TAG=v2.8.3-harbor.1-rc.1

#
# Stage 1: builder — cross-compile BOTH harbor_registryctl AND the registry
# binary from goharbor/distribution. registryctl bundles the registry binary
# because it orchestrates registry-side GC operations.
#
FROM golang:1.25.7 AS builder

ARG HARBOR_REF
ARG REGISTRY_SRC_TAG
ARG TARGETOS
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${HARBOR_REF}" https://github.com/goharbor/harbor.git .

# Build harbor_registryctl.
ENV CGO_ENABLED=0
RUN set -eux; \
    cd src/registryctl; \
    GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
      go build -buildvcs=false -ldflags "-w -s" \
        -o /out/harbor_registryctl .

# Build the distribution registry binary — same steps as the harbor-registry
# image. GOPATH mode, vendor-based.
ENV GOPATH=/go
ENV DISTRIBUTION_DIR=/go/src/github.com/docker/distribution
RUN mkdir -p "$(dirname "${DISTRIBUTION_DIR}")" \
    && git clone --depth 1 --branch "${REGISTRY_SRC_TAG}" \
        https://github.com/goharbor/distribution.git "${DISTRIBUTION_DIR}"

ENV BUILDTAGS="include_oss include_gcs"
ENV GO111MODULE=auto

RUN set -eux; \
    cd "${DISTRIBUTION_DIR}"; \
    GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
      make PREFIX=/go clean binaries; \
    cp bin/registry /out/registry

RUN set -eux; \
    mkdir -p /out/assets; \
    cp /src/make/photon/common/install_cert.sh    /out/assets/; \
    cp /src/make/photon/registryctl/start.sh      /out/assets/

#
# Stage 2: runtime — photon:5.0 + harbor user, mirroring upstream
# harbor-registryctl-base (note: this one lives at /home/harbor, not /harbor).
#
FROM photon:5.0

ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="harbor-registryctl" \
      org.opencontainers.image.description="Harbor registry controller (with bundled registry binary) on Photon OS 5.0 (multi-arch rebuild of goharbor/registryctl)" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/goharbor/harbor" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

RUN tdnf install -y shadow ca-certificates >> /dev/null \
    && tdnf clean all \
    && groupadd -r -g 10000 harbor \
    && useradd --no-log-init -m -g 10000 -u 10000 harbor

COPY --from=builder /out/harbor_registryctl      /home/harbor/harbor_registryctl
COPY --from=builder /out/registry                /usr/bin/registry_DO_NOT_USE_GC
COPY --from=builder /out/assets/install_cert.sh  /home/harbor/install_cert.sh
COPY --from=builder /out/assets/start.sh         /home/harbor/start.sh

RUN chown -R harbor:harbor /etc/pki/tls/certs \
    && chown harbor:harbor /home/harbor/harbor_registryctl   && chmod u+x /home/harbor/harbor_registryctl \
    && chown harbor:harbor /usr/bin/registry_DO_NOT_USE_GC   && chmod u+x /usr/bin/registry_DO_NOT_USE_GC \
    && chown harbor:harbor /home/harbor/start.sh             && chmod u+x /home/harbor/start.sh \
    && chown harbor:harbor /home/harbor/install_cert.sh      && chmod u+x /home/harbor/install_cert.sh

VOLUME ["/var/lib/registry"]

HEALTHCHECK CMD curl --fail -s http://localhost:8080/api/health \
        || curl -sk --fail \
              --key /etc/harbor/ssl/registryctl.key \
              --cert /etc/harbor/ssl/registryctl.crt \
              https://localhost:8443/api/health \
        || exit 1

USER harbor

ENTRYPOINT ["/home/harbor/start.sh"]
