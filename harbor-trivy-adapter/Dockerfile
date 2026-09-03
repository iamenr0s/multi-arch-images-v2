# syntax=docker/dockerfile:1.26@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32

ARG HARBOR_REF=v2.15.0
ARG TRIVY_ADAPTER_REF=v0.35.1
ARG TRIVY_VERSION=v0.69.3

#
# Stage 1: builder — cross-compile scanner-trivy and download the Trivy binary
# for the target arch.
#
FROM golang:1.27.1@sha256:512690a5660563b57d37ecc31129e7f136e831db2aed24a1dbeb8ad7380dc0fa AS builder

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
    TRIVY_TARBALL="trivy_${TRIVY_VER_NOV}_${TRIVY_ASSET}.tar.gz"; \
    curl -fsSL --retry 3 -o "/tmp/${TRIVY_TARBALL}" \
      "https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/${TRIVY_TARBALL}"; \
    curl -fsSL --retry 3 \
      "https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VER_NOV}_checksums.txt" \
      | grep " ${TRIVY_TARBALL}$" | (cd /tmp && sha256sum -c -); \
    mkdir -p /tmp/trivy; \
    tar -xzf "/tmp/${TRIVY_TARBALL}" -C /tmp/trivy; \
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
FROM photon:5.0@sha256:ab4b68e15c8ff6b9c79ba525f696260f772c711761d576dd53bf43c351c9a504

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
