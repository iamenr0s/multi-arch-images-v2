# syntax=docker/dockerfile:1.7

ARG HARBOR_REF=v2.15.0
ARG TRIVY_ADAPTER_REF=v0.35.1
ARG TRIVY_VERSION=v0.69.3

#
# Stage 1: builder — cross-compile scanner-trivy and download the Trivy binary
# for the target arch.
#
FROM --platform=$BUILDPLATFORM golang:1.25.7 AS builder

ARG HARBOR_REF
ARG TRIVY_ADAPTER_REF
ARG TRIVY_VERSION
ARG TARGETOS
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${HARBOR_REF}" https://github.com/goharbor/harbor.git .

# Build scanner-trivy from goharbor/harbor-scanner-trivy.
RUN git clone --depth 1 --branch "${TRIVY_ADAPTER_REF}" \
    https://github.com/goharbor/harbor-scanner-trivy.git /scanner-src

ENV CGO_ENABLED=0
RUN set -eux; \
    cd /scanner-src; \
    GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
      go build -ldflags "-w -s" -o /out/scanner-trivy ./cmd/scanner-trivy

# Download the Trivy binary. Upstream release assets use a per-arch naming
# convention: amd64 -> Linux-64bit, arm64 -> Linux-ARM64.
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) TRIVY_ASSET="Linux-64bit" ;; \
      arm64) TRIVY_ASSET="Linux-ARM64" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    TRIVY_VER_NOV="${TRIVY_VERSION#v}"; \
    curl -fsSL -o /tmp/trivy.tar.gz \
      "https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VER_NOV}_${TRIVY_ASSET}.tar.gz"; \
    mkdir -p /tmp/trivy; \
    tar -xzf /tmp/trivy.tar.gz -C /tmp/trivy; \
    cp /tmp/trivy/trivy /out/trivy; \
    chmod +x /out/trivy

RUN set -eux; \
    mkdir -p /out/assets; \
    cp /src/make/photon/common/install_cert.sh       /out/assets/; \
    cp /src/make/photon/trivy-adapter/entrypoint.sh  /out/assets/

#
# Stage 2: runtime — photon:5.0 + scanner user (UID/GID 10000), mirroring
# upstream harbor-trivy-adapter-base (note: user is "scanner", not "harbor").
#
FROM --platform=$TARGETPLATFORM photon:5.0

ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown
ARG TRIVY_VERSION

LABEL org.opencontainers.image.title="harbor-trivy-adapter" \
      org.opencontainers.image.description="Harbor Trivy scanner adapter on Photon OS 5.0 (multi-arch rebuild of goharbor/trivy-adapter-photon)" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/goharbor/harbor" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

RUN tdnf install -y rpm shadow ca-certificates >> /dev/null \
    && tdnf clean all \
    && groupadd --system --gid 10000 scanner \
    && useradd --system --uid 10000 --gid 10000 -m -d /home/scanner -s /sbin/nologin scanner \
    && mkdir -p /home/scanner/bin \
    && chown -R scanner:scanner /home/scanner

COPY --from=builder /out/scanner-trivy             /home/scanner/bin/scanner-trivy
COPY --from=builder /out/trivy                     /usr/local/bin/trivy
COPY --from=builder /out/assets/entrypoint.sh      /home/scanner/entrypoint.sh
COPY --from=builder /out/assets/install_cert.sh    /home/scanner/install_cert.sh

RUN chown -R scanner:scanner /etc/pki/tls/certs \
    && chown scanner:scanner /home/scanner/entrypoint.sh       && chmod u+x /home/scanner/entrypoint.sh \
    && chown scanner:scanner /usr/local/bin/trivy              && chmod u+x /usr/local/bin/trivy \
    && chown scanner:scanner /home/scanner/bin/scanner-trivy   && chmod u+x /home/scanner/bin/scanner-trivy \
    && chown scanner:scanner /home/scanner/install_cert.sh     && chmod u+x /home/scanner/install_cert.sh

ENV TRIVY_VERSION=${TRIVY_VERSION}

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl --fail -s http://localhost:8080/probe/healthy \
        || curl -k --fail -s https://localhost:8443/probe/healthy \
        || exit 1

USER scanner

ENTRYPOINT ["/home/scanner/entrypoint.sh"]
