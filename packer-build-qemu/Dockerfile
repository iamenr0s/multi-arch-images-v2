FROM alpine:3.24

LABEL maintainer="iamenr0s"

ARG PACKER_VERSION=1.11.2

RUN apk add --update git bash curl openssl libvirt-daemon qemu qemu-system-`uname -m | sed 's|armv7l|arm|'` qemu-img

RUN set -eux; \
 PACKER_ARCH=$(uname -m | sed 's|armv7l|arm|' | sed 's|x86_64|amd64|' | sed 's|aarch64|arm64|'); \
 PACKER_ZIP="packer_${PACKER_VERSION}_linux_${PACKER_ARCH}.zip"; \
 curl -sfL --retry 3 -o "/tmp/${PACKER_ZIP}" "https://releases.hashicorp.com/packer/${PACKER_VERSION}/${PACKER_ZIP}"; \
 curl -sfL --retry 3 "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS" | grep " ${PACKER_ZIP}$" | (cd /tmp && sha256sum -c -); \
 unzip "/tmp/${PACKER_ZIP}" -d /usr/local/bin; \
 rm -f "/tmp/${PACKER_ZIP}"
