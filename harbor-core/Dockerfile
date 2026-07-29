# syntax=docker/dockerfile:1.25@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

ARG HARBOR_REF=v2.15.1
ARG SWAGGER_VERSION=v0.33.1

#
# Stage 1: builder — cross-compile harbor_core on the build host's native arch
#
FROM golang:1.26.5@sha256:3aff6657219a4d9c14e27fb1d8976c49c29fddb70ba835014f477e1c70636647 AS builder

ARG HARBOR_REF
ARG SWAGGER_VERSION
ARG TARGETOS
ARG TARGETARCH
ARG BUILDARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Pinned to the same go-swagger version that upstream's Makefile uses (SWAGGER_VERSION).
RUN set -eux; \
    curl -fsSL --retry 3 -o "/tmp/swagger_linux_${BUILDARCH}" \
      "https://github.com/go-swagger/go-swagger/releases/download/${SWAGGER_VERSION}/swagger_linux_${BUILDARCH}"; \
    curl -fsSL --retry 3 \
      "https://github.com/go-swagger/go-swagger/releases/download/${SWAGGER_VERSION}/sha256sum.txt" \
      | grep " swagger_linux_${BUILDARCH}$" | (cd /tmp && sha256sum -c -); \
    mv "/tmp/swagger_linux_${BUILDARCH}" /usr/local/bin/swagger; \
    chmod +x /usr/local/bin/swagger

WORKDIR /src

RUN git clone --depth 1 --branch "${HARBOR_REF}" https://github.com/goharbor/harbor.git .

# Mirrors the Makefile swagger_generate_server macro. restapi/models are gitignored
# upstream so the codegen must run before `go build`.
RUN rm -rf src/server/v2.0/models src/server/v2.0/restapi \
    && mkdir -p src/server/v2.0 \
    && swagger generate server \
         --template-dir=tools/swagger/templates \
         --exclude-main \
         --additional-initialism=CVE \
         --additional-initialism=GC \
         --additional-initialism=OIDC \
         -f api/v2.0/swagger.yaml \
         -A harbor \
         --target src/server/v2.0

# Cross-compile with the same ldflags pattern as the upstream compile_core target.
ENV CGO_ENABLED=0
RUN set -eux; \
    RELEASEVERSION="$(cat VERSION)"; \
    GITCOMMIT="$(git rev-parse --short=8 HEAD)"; \
    cd src/core; \
    GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
      go build -buildvcs=false \
        -ldflags "-w -s \
          -X github.com/goharbor/harbor/src/pkg/version.GitCommit=${GITCOMMIT} \
          -X github.com/goharbor/harbor/src/pkg/version.ReleaseVersion=${RELEASEVERSION}" \
        -o /out/harbor_core .

# Generate make/photon/prepare/versions (gitignored upstream, produced by the
# root Makefile's versions_prepare target).
RUN make versions_prepare

# Collect runtime assets in one place for a clean COPY --from=builder.
RUN set -eux; \
    mkdir -p /out/assets; \
    cp make/photon/common/install_cert.sh /out/assets/; \
    cp make/photon/core/entrypoint.sh     /out/assets/; \
    cp make/photon/prepare/versions       /out/assets/; \
    cp -r src/core/views                  /out/assets/views; \
    cp -r make/migrations                 /out/assets/migrations; \
    cp -r icons                           /out/assets/icons

#
# Stage 2: runtime — photon:5.0, mirroring upstream harbor-core-base layout
#
FROM photon:5.0@sha256:ab4b68e15c8ff6b9c79ba525f696260f772c711761d576dd53bf43c351c9a504

ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="harbor-core" \
      org.opencontainers.image.description="Harbor core API server on Photon OS 5.0 (multi-arch rebuild of goharbor/harbor-core)" \
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

COPY --from=builder /out/harbor_core             /harbor/harbor_core
COPY --from=builder /out/assets/entrypoint.sh    /harbor/entrypoint.sh
COPY --from=builder /out/assets/install_cert.sh  /harbor/install_cert.sh
COPY --from=builder /out/assets/versions         /harbor/versions
COPY --from=builder /out/assets/views            /harbor/views
COPY --from=builder /out/assets/migrations       /harbor/migrations
COPY --from=builder /out/assets/icons            /harbor/icons

RUN chown -R harbor:harbor /etc/pki/tls/certs /harbor \
    && chmod u+x /harbor/entrypoint.sh /harbor/install_cert.sh /harbor/harbor_core

HEALTHCHECK CMD curl --fail -s http://localhost:8080/api/v2.0/ping \
        || curl -k --fail -s https://localhost:8443/api/v2.0/ping \
        || exit 1

USER harbor

ENTRYPOINT ["/harbor/entrypoint.sh"]
