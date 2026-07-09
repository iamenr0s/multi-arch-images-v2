FROM almalinux:10 AS prep_files

ARG KIBANA_VERSION=9.3.2
ARG NODEJS_VERSION=v25.6.1

RUN yum install -y yum-utils && \
 yum-config-manager --enable crb && \
 yum install -y --allowerasing glibc-static gcc make curl tar gzip

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

# Checksum of the v1.2.5 tag archive; recompute when bumping the version.
ARG DUMB_INIT_SHA256=28ef31387b6324494175ec0bd01767470ff01e454ef610e1360cc774f87f5f62
RUN mkdir -p /opt/dumb-init
RUN set -eux; \
 curl -sfL --retry 3 -o /tmp/dumb-init.tar.gz https://github.com/Yelp/dumb-init/archive/v1.2.5.tar.gz; \
 echo "${DUMB_INIT_SHA256}  /tmp/dumb-init.tar.gz" | sha256sum -c -; \
 tar -C /opt/dumb-init --strip-components=1 -zxf /tmp/dumb-init.tar.gz; \
 rm -f /tmp/dumb-init.tar.gz
RUN cd /opt/dumb-init && make

RUN chmod -R g=u /usr/share/kibana
RUN find /usr/share/kibana -type d -exec chmod g+s {} \;

FROM almalinux:10
EXPOSE 5601

RUN yum update -y && yum install -y fontconfig freetype shadow-utils && yum clean all

COPY --from=prep_files --chown=1000:0 /usr/share/kibana /usr/share/kibana
COPY --from=prep_files --chown=1000:0 /opt/dumb-init/dumb-init /usr/local/bin/dumb-init

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
