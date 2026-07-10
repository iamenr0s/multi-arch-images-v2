FROM almalinux:10 AS prep_files

ARG KIBANA_VERSION=9.3.2
ARG NODEJS_VERSION=v25.6.1

RUN yum install -y --allowerasing curl tar gzip

RUN mkdir /usr/share/kibana
WORKDIR /usr/share/kibana

RUN set -eux; \
 KIBANA_TARBALL="kibana-${KIBANA_VERSION}-linux-$(uname -m).tar.gz"; \
 curl -sfL --retry 3 -o "/tmp/${KIBANA_TARBALL}" "https://artifacts.elastic.co/downloads/kibana/${KIBANA_TARBALL}"; \
 curl -sfL --retry 3 "https://artifacts.elastic.co/downloads/kibana/${KIBANA_TARBALL}.sha512" | (cd /tmp && sha512sum -c -); \
 tar --strip-components=1 -zxf "/tmp/${KIBANA_TARBALL}"; \
 rm -f "/tmp/${KIBANA_TARBALL}"
RUN set -eux; \
 NODE_ARCH=$(uname -m | sed 's|x86_64|x64|' | sed 's|aarch64|arm64|'); \
 NODE_TARBALL="node-${NODEJS_VERSION}-linux-${NODE_ARCH}.tar.gz"; \
 curl -sfL --retry 3 -o "/tmp/${NODE_TARBALL}" "https://nodejs.org/dist/${NODEJS_VERSION}/${NODE_TARBALL}"; \
 curl -sfL --retry 3 "https://nodejs.org/dist/${NODEJS_VERSION}/SHASUMS256.txt" | grep " ${NODE_TARBALL}$" | (cd /tmp && sha256sum -c -); \
 rm -rf /usr/share/kibana/node/*; \
 tar -C /usr/share/kibana/node/ --strip-components=1 -xzf "/tmp/${NODE_TARBALL}"; \
 rm -f "/tmp/${NODE_TARBALL}"

# Official static release binary, verified against the published sha256sums.
# (GitHub /archive/ tarballs are not byte-stable, so they can't be checksummed.)
ARG DUMB_INIT_VERSION=1.2.5
RUN set -eux; \
 DUMB_INIT_BIN="dumb-init_${DUMB_INIT_VERSION}_$(uname -m)"; \
 curl -sfL --retry 3 -o "/tmp/${DUMB_INIT_BIN}" "https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/${DUMB_INIT_BIN}"; \
 curl -sfL --retry 3 "https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/sha256sums" | grep -F "*${DUMB_INIT_BIN}" | (cd /tmp && sha256sum -c -); \
 install -m 0755 "/tmp/${DUMB_INIT_BIN}" /usr/local/bin/dumb-init; \
 rm -f "/tmp/${DUMB_INIT_BIN}"

RUN chmod -R g=u /usr/share/kibana
RUN find /usr/share/kibana -type d -exec chmod g+s {} \;

FROM almalinux:10
EXPOSE 5601

RUN yum update -y && yum install -y fontconfig freetype shadow-utils && yum clean all

COPY --from=prep_files --chown=1000:0 /usr/share/kibana /usr/share/kibana
COPY --from=prep_files --chown=1000:0 /usr/local/bin/dumb-init /usr/local/bin/dumb-init

WORKDIR /usr/share/kibana
RUN ln -s /usr/share/kibana /opt/kibana

ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/kibana/bin:$PATH

COPY --chown=1000:0 config/kibana.yml /usr/share/kibana/config/kibana.yml
COPY --chown=1000:0 bin/kibana-docker /usr/local/bin/

RUN chmod g+ws /usr/share/kibana && find /usr/share/kibana -gid 0 -and -not -perm /g+w -exec chmod g+w {} \;

RUN groupadd --gid 1000 kibana && useradd --uid 1000 --gid 1000 --home-dir /usr/share/kibana --no-create-home kibana
USER kibana

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/usr/local/bin/kibana-docker"]
