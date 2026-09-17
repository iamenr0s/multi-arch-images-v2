ARG VERSION=latest
# this allows to override gvm-libs for e.g. smoketests
ARG GVM_LIBS=ghcr.io/greenbone/gvm-libs
ARG RUST_IMAGE=rust@sha256:bf5a9aa29062a6cb03c49bd59a46eb55e3cc770caf598a221a7866e500be3082
ARG OPENVAS_SMB_IMAGE=greenbone/openvas-smb@sha256:e96e0c5db6d619a4e6e240ba9a3f6186a2395faa7379ef1419dd3938f4bd16af
ARG BUILD_IMAGE=${GVM_LIBS}:${VERSION}
ARG FINAL_IMAGE=${GVM_LIBS}:${VERSION}
ARG FINAL_PACKAGE_SET=${VERSION}

# Stage 1: Clone upstream source (includes the .docker/ build files and Makefile)
FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS source
ARG OPENVAS_SCANNER_REF=main
# make -C /app/.docker fetches and extracts the vendored krb5/libpcap
# source trees the static builds below need; upstream ships this as a
# separate make step rather than committing the tarball contents.
RUN apk add --no-cache git make curl tar \
    && git clone --depth 1 --branch ${OPENVAS_SCANNER_REF} https://github.com/greenbone/openvas-scanner /app \
    && make -C /app/.docker

FROM ${RUST_IMAGE} AS krb5-build
ARG KRB5_VERSION=1.22.2

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    bison \
    ca-certificates \
    make \
    && rm -rf /var/lib/apt/lists/*

COPY --from=source /app/.docker/vendor/krb5-${KRB5_VERSION} /tmp/krb5-${KRB5_VERSION}
# Build only the MIT krb5 subtrees that produce the static archives and
# headers used by the Rust build; the full tree pulls in broken utility
# targets we do not need here.
WORKDIR "/tmp/krb5-${KRB5_VERSION}/src"
RUN ./configure --prefix=/opt/krb5-static \
        --enable-static \
        --disable-shared \
        --without-system-verto \
        --without-libedit \
        --disable-rpath \
    && make -C util/support -j"$(nproc)" \
    && make -C util/et -j"$(nproc)" \
    && make -C util/profile -j"$(nproc)" \
    && make -C include -j"$(nproc)" \
    && make -C lib/crypto -j"$(nproc)" \
    && make -C lib/krb5 -j"$(nproc)" \
    && make -C lib/gssapi -j"$(nproc)" \
    && make install-mkdirs \
    && make -C util/support install \
    && make -C util/et install \
    && make -C util/profile install \
    && make -C include install \
    && make -C lib/crypto install \
    && make -C lib/krb5 install \
    && make -C lib/gssapi install \
    && test -f /opt/krb5-static/lib/libgssapi_krb5.a \
    && test -f /opt/krb5-static/lib/libkrb5.a \
    && test -f /opt/krb5-static/lib/libk5crypto.a \
    && test -f /opt/krb5-static/lib/libcom_err.a \
    && test -f /opt/krb5-static/lib/libkrb5support.a

FROM ${RUST_IMAGE} AS pcap-build
ARG LIBPCAP_VERSION=1.10.6

# Debian's static libpcap from `apt-get install libpcap-dev` pulls in
# libsystemd.a and libdbus-1.a. Build libpcap from source instead so the
# Rust binaries do not need those unused static link dependencies.
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    bison \
    ca-certificates \
    flex \
    make \
    && rm -rf /var/lib/apt/lists/*

COPY --from=source /app/.docker/vendor/libpcap-${LIBPCAP_VERSION} /tmp/libpcap-${LIBPCAP_VERSION}

WORKDIR "/tmp/libpcap-${LIBPCAP_VERSION}"
RUN ./configure --prefix=/opt/libpcap-static \
        --disable-shared \
        --disable-dbus \
    && make -j"$(nproc)" \
    && make install \
    && test -f /opt/libpcap-static/lib/libpcap.a \
    && test -f /opt/libpcap-static/include/pcap.h

FROM ${RUST_IMAGE} AS build-archives

COPY --from=krb5-build /opt/krb5-static /opt/krb5-static
COPY --from=pcap-build /opt/libpcap-static /opt/libpcap-static

RUN mkdir -p /archives/include/gssapi /archives/include/krb5 \
    && install -m 644 /opt/libpcap-static/lib/libpcap.a /archives/libpcap.a \
    && install -m 644 /opt/krb5-static/lib/libgssapi_krb5.a /archives/libgssapi_krb5.a \
    && install -m 644 /opt/krb5-static/lib/libkrb5.a /archives/libkrb5.a \
    && install -m 644 /opt/krb5-static/lib/libk5crypto.a /archives/libk5crypto.a \
    && install -m 644 /opt/krb5-static/lib/libcom_err.a /archives/libcom_err.a \
    && install -m 644 /opt/krb5-static/lib/libkrb5support.a /archives/libkrb5support.a \
    && install -m 644 /opt/libpcap-static/include/pcap.h /archives/include/pcap.h \
    && install -m 644 /opt/krb5-static/include/krb5.h /archives/include/krb5.h \
    && install -m 644 /opt/krb5-static/include/com_err.h /archives/include/com_err.h \
    && install -m 644 /opt/krb5-static/include/profile.h /archives/include/profile.h \
    && install -m 644 /opt/krb5-static/include/gssapi/gssapi.h /archives/include/gssapi/gssapi.h \
    && install -m 644 /opt/krb5-static/include/gssapi/gssapi_alloc.h /archives/include/gssapi/gssapi_alloc.h \
    && install -m 644 /opt/krb5-static/include/gssapi/gssapi_ext.h /archives/include/gssapi/gssapi_ext.h \
    && install -m 644 /opt/krb5-static/include/gssapi/gssapi_generic.h /archives/include/gssapi/gssapi_generic.h \
    && install -m 644 /opt/krb5-static/include/gssapi/gssapi_krb5.h /archives/include/gssapi/gssapi_krb5.h \
    && install -m 644 /opt/krb5-static/include/gssapi/mechglue.h /archives/include/gssapi/mechglue.h \
    && install -m 644 /opt/krb5-static/include/krb5/krb5.h /archives/include/krb5/krb5.h

FROM ${RUST_IMAGE} AS rust
ARG BIN_VERSION=
ENV BIN_VERSION=${BIN_VERSION}
COPY --from=source /app /source
COPY --from=build-archives /archives /archives
# if we have already binaries available we don't need to build them again
RUN (mv /source/.docker/install /install || true) \
    && mkdir -p /install/usr/local/bin \
    && ls -las /install/usr/local/bin/
WORKDIR /source/rust
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    capnproto \
    ca-certificates \
    libclang-dev \
    libsnmp-dev \
    && rm -rf /var/lib/apt/lists/*
ENV OPENVAS_ARCHIVES=/archives \
    LIBPCAP_LIBDIR=/archives

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=/source/rust/target \
  [ -f /install/usr/local/bin/openvasd ] && \
  [ -f /install/usr/local/bin/scannerctl ] || \
    ( cargo build --release && \
    install -Dm755 target/release/openvasd /install/usr/local/bin/openvasd && \
    install -Dm755 target/release/scannerctl /install/usr/local/bin/scannerctl )

# this is needed when we just want to copy the build binaries onto our dest dir
FROM scratch AS rs-binaries
COPY --from=rust /install /install

FROM ${OPENVAS_SMB_IMAGE} AS openvas-smb

FROM ${BUILD_IMAGE} AS build
COPY --from=source /app /source
RUN sh /source/.github/install-openvas-dependencies.sh \
    && apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    capnproto \
    && rm -rf /var/lib/apt/lists/*
COPY --from=openvas-smb /usr/local/lib/ /usr/local/lib/
RUN cmake -DCMAKE_BUILD_TYPE=Release -DINSTALL_OLD_SYNC_SCRIPT=OFF -B/build /source \
    && DESTDIR=/install cmake --build /build -- install

FROM scratch AS prepared
COPY --from=build /install /install
COPY --from=rs-binaries /install/usr/local/bin/openvasd /install/usr/local/bin/openvasd
COPY --from=rs-binaries /install/usr/local/bin/scannerctl /install/usr/local/bin/scannerctl

FROM ${FINAL_IMAGE} AS pypsrp-cli-build
ARG VERSION
# hadolint ignore=DL4006
RUN if ! printf '%s' "${VERSION}" | grep -q -- '-edge$'; then \
      suite_name="${VERSION}"; \
      if [ "${suite_name}" = "latest" ]; then suite_name=stable; fi; \
      . /etc/os-release && sed -i "s/${suite_name}/$VERSION_CODENAME/g" /etc/apt/sources.list.d/*.sources; \
    fi
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -y \
        gcc \
        git \
        krb5-user \
        libkrb5-dev \
        python3 \
        python3-dev \
        python3-gssapi \
        python3-pip \
        python3-requests \
    && rm -rf /var/lib/apt/lists/*
ARG PYPSRP_CLI_VERSION=v0.1.0
RUN git clone --depth 1 --branch "${PYPSRP_CLI_VERSION}" https://github.com/greenbone/pypsrp-cli.git /tmp/pypsrp-cli \
    && python3 -m pip install --break-system-packages --no-cache-dir --root /install /tmp/pypsrp-cli \
    && test -x /install/usr/local/bin/pypsrp-cli \
    && rm -rf /tmp/pypsrp-cli

FROM ${FINAL_IMAGE}
ARG VERSION
ARG FINAL_PACKAGE_SET
ARG IMAGE_VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown
LABEL org.opencontainers.image.title="openvas-scanner" \
      org.opencontainers.image.description="OpenVAS Scanner is the scanner component of the Greenbone vulnerability management stack" \
      org.opencontainers.image.licenses="GPL-2.0" \
      org.opencontainers.image.source="https://github.com/greenbone/openvas-scanner" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"
COPY --from=source /app/.docker/packages /tmp/openvas-packages
# We rewrite suite aliases to VERSION_CODENAME for fixed-release images.
# Edge/testing-style tags skip that rewrite on purpose.
# hadolint ignore=DL4006
RUN if ! printf '%s' "${VERSION}" | grep -q -- '-edge$'; then \
      suite_name="${VERSION}"; \
      if [ "${suite_name}" = "latest" ]; then suite_name=stable; fi; \
      . /etc/os-release && sed -i "s/${suite_name}/$VERSION_CODENAME/g" /etc/apt/sources.list.d/*.sources; \
    fi
RUN test -f "/tmp/openvas-packages/${FINAL_PACKAGE_SET}.txt" \
    && apt-get update \
    && xargs -a "/tmp/openvas-packages/${FINAL_PACKAGE_SET}.txt" apt-get install --no-install-recommends --no-install-suggests -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -y \
        krb5-user \
        python3 \
        python3-pip \
        python3-gssapi \
        python3-requests \
    && rm -rf /var/lib/apt/lists/*

# produces the bug ` '/usr/share/doc/python3-impacket/examples/wmiexec.py': [Errno 2] No such file or directory`
# cryptography produces a dependency conflict with the cryptography installed by impacket (later via pip)
# install impacket via pip and not apt-get to get the latest version
# openvas is expecting impacket-wmiexec to be in the path although it got renamed
# until openvas is fixed we create a symlink
RUN (apt-get remove -y python3-impacket python3-cryptography || true) \
    && apt-get autoremove -y \
    && python3 -m pip install --break-system-packages --no-cache-dir --ignore-installed impacket \
    && ln -s /usr/local/bin/wmiexec.py /usr/local/bin/impacket-wmiexec

# must be pre built within the rust dir and moved to the bin dir
# usually this image is created within in a ci ensuring that the
# binary is available.
COPY --from=prepared /install/ /
COPY --from=pypsrp-cli-build /install/usr/local/ /usr/local/
COPY --from=openvas-smb /usr/local/lib/ /usr/local/lib/
COPY --from=openvas-smb /usr/local/bin/ /usr/local/bin/
# allow openvas to access raw sockets and all kind of network related tasks
# allow nmap to send e.g. UDP or TCP SYN probes without root permissions
ENV NMAP_PRIVILEGED=1
RUN ldconfig \
    && setcap cap_net_raw,cap_net_admin+eip /usr/local/sbin/openvas \
    && setcap cap_net_raw,cap_net_admin,cap_net_bind_service+eip /usr/bin/nmap \
    && chmod 755 /usr/local/bin/scannerctl \
    && chmod 755 /usr/local/bin/openvasd \
    && mkdir -p /var/lib/openvasd/certs
CMD ["/usr/local/bin/openvasd"]
