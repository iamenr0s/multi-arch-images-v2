FROM alpine:3.21 AS build_stage

WORKDIR /
RUN apk --update add python3 py3-pip build-base automake libtool m4 autoconf libevent-dev openssl-dev c-ares-dev curl jq
RUN pip3 install --break-system-packages docutils \
 && LATEST_TAG=$(curl -sf https://api.github.com/repos/pgbouncer/pgbouncer/releases/latest | jq -r '.tag_name') \
 && PGBOUNCER_VERSION=$(echo "${LATEST_TAG}" | sed 's/pgbouncer_//;s/_/./g') \
 && curl -sfL "https://github.com/pgbouncer/pgbouncer/releases/download/${LATEST_TAG}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz" -o pgbouncer.tar.gz \
 && mkdir /pgbouncer-src \
 && tar zxf pgbouncer.tar.gz --strip-components=1 -C /pgbouncer-src \
 && rm pgbouncer.tar.gz \
 && cd /pgbouncer-src \
 && ./configure --prefix=/pgbouncer \
 && make \
 && make install

FROM alpine:3.21

RUN apk --update add libevent openssl c-ares
WORKDIR /
COPY --from=build_stage /pgbouncer /pgbouncer
ADD entrypoint.sh ./

ENTRYPOINT ["./entrypoint.sh"]
