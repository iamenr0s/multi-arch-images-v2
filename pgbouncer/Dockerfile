FROM alpine:3.21 AS build_stage

ARG PGBOUNCER_VERSION=1.25.1

WORKDIR /
RUN apk --update add python3 py3-pip build-base automake libtool m4 autoconf libevent-dev openssl-dev c-ares-dev curl
RUN pip3 install --break-system-packages docutils \
 && curl -sL https://github.com/pgbouncer/pgbouncer/archive/refs/tags/pgbouncer_$(echo "$PGBOUNCER_VERSION" | sed 's/\./\_/g').tar.gz -o pgbouncer.tar.gz \
 && tar zxf pgbouncer.tar.gz && rm pgbouncer.tar.gz \
 && cd /pgbouncer-${PGBOUNCER_VERSION}/ \
 && ./configure --prefix=/pgbouncer \
 && make \
 && make install

FROM alpine:3.21

RUN apk --update add libevent openssl c-ares
WORKDIR /
COPY --from=build_stage /pgbouncer /pgbouncer
ADD entrypoint.sh ./

ENTRYPOINT ["./entrypoint.sh"]
