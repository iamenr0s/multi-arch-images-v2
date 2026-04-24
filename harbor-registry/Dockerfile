# syntax=docker/dockerfile:1.7

ARG HARBOR_REF=v2.15.0
# Harbor ships a forked distribution that adds Redis cache support. The tag is
# pinned to the upstream Harbor Makefile's REGISTRY_SRC_TAG.
ARG REGISTRY_SRC_TAG=v2.8.3-harbor.1-rc.1

#
# Stage 1: builder — cross-compile the registry binary on the build host's
# native arch.
#
FROM --platform=$BUILDPLATFORM golang:1.25.7 AS builder

ARG HARBOR_REF
ARG REGISTRY_SRC_TAG
ARG TARGETOS
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates make \
    && rm -rf /var/lib/apt/lists/*

# goharbor/distribution predates Go modules — it uses GOPATH mode with a vendor
# directory, so it must live under $GOPATH/src/github.com/docker/distribution.
ENV GOPATH=/go
ENV DISTRIBUTION_DIR=/go/src/github.com/docker/distribution
RUN mkdir -p $(dirname "${DISTRIBUTION_DIR}") \
    && git clone --depth 1 --branch "${REGISTRY_SRC_TAG}" \
        https://github.com/goharbor/distribution.git "${DISTRIBUTION_DIR}"

# BUILDTAGS match upstream Harbor's Dockerfile.binary: include the OSS and GCS
# storage drivers on top of the default filesystem/S3/Azure set.
ENV BUILDTAGS="include_oss include_gcs"
ENV GO111MODULE=auto
ENV CGO_ENABLED=0

RUN set -eux; \
    cd "${DISTRIBUTION_DIR}"; \
    GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
      make PREFIX=/go clean binaries; \
    mkdir -p /out; \
    cp bin/registry /out/registry

# Clone the Harbor repo at the target release to pick up the registry
# entrypoint + cert-install scripts.
RUN set -eux; \
    git clone --depth 1 --branch "${HARBOR_REF}" \
        https://github.com/goharbor/harbor.git /harbor-src; \
    mkdir -p /out/assets; \
    cp /harbor-src/make/photon/common/install_cert.sh   /out/assets/; \
    cp /harbor-src/make/photon/registry/entrypoint.sh   /out/assets/

#
# Stage 2: runtime — photon:5.0, mirroring upstream harbor-registry-base layout.
#
# Explicit --platform=$TARGETPLATFORM: without it, podman keys the FROM layer by
# image name only and serves the amd64 photon from cache during the arm64 build,
# producing an arm64-labelled image with amd64 content.
#
FROM --platform=$TARGETPLATFORM photon:5.0

ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="harbor-registry" \
      org.opencontainers.image.description="Harbor registry (goharbor/distribution fork with Redis cache) on Photon OS 5.0 (multi-arch rebuild of goharbor/registry-photon)" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/goharbor/harbor" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

RUN tdnf install -y shadow >> /dev/null \
    && tdnf clean all \
    && mkdir -p /etc/registry /storage \
    && groupadd -r -g 10000 harbor \
    && useradd --no-log-init -m -g 10000 -u 10000 harbor \
    && chown harbor:harbor /storage

COPY --from=builder /out/registry                /usr/bin/registry_DO_NOT_USE_GC
COPY --from=builder /out/assets/install_cert.sh  /home/harbor/install_cert.sh
COPY --from=builder /out/assets/entrypoint.sh    /home/harbor/entrypoint.sh

RUN chown -R harbor:harbor /etc/pki/tls/certs \
    && chown harbor:harbor /home/harbor/entrypoint.sh   && chmod u+x /home/harbor/entrypoint.sh \
    && chown harbor:harbor /home/harbor/install_cert.sh && chmod u+x /home/harbor/install_cert.sh \
    && chown harbor:harbor /usr/bin/registry_DO_NOT_USE_GC && chmod u+x /usr/bin/registry_DO_NOT_USE_GC

VOLUME ["/storage"]

HEALTHCHECK CMD curl --fail -s http://localhost:5000 \
        || curl -k --fail -s https://localhost:5443 \
        || exit 1

USER harbor

ENTRYPOINT ["/home/harbor/entrypoint.sh"]
