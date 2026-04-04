FROM almalinux:9 AS prep_files

ARG KIBANA_VERSION=9.3.2
ARG NODEJS_VERSION=v25.6.1

RUN yum install -y glibc-static gcc make curl tar gzip

RUN mkdir /usr/share/kibana
WORKDIR /usr/share/kibana

RUN curl -sL https://artifacts.elastic.co/downloads/kibana/kibana-oss-${KIBANA_VERSION}-linux-`uname -m`.tar.gz | tar --strip-components=1 -zxf -
RUN rm -rf /usr/share/kibana/node/* && \
 curl -sL https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-linux-`uname -m|sed 's|x86_64|x64|'|sed 's|aarch64|arm64|'`.tar.gz | tar -C /usr/share/kibana/node/ --strip-components=1 -xzf -

RUN mkdir -p /opt/dumb-init
RUN curl -sL https://github.com/Yelp/dumb-init/archive/v1.2.5.tar.gz | tar -C /opt/dumb-init --strip-components=1 -zxf -
RUN cd /opt/dumb-init && make

RUN chmod -R g=u /usr/share/kibana
RUN find /usr/share/kibana -type d -exec chmod g+s {} \;

FROM almalinux:9
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
