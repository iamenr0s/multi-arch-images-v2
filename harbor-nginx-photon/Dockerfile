FROM photon:5.0@sha256:6db86de5ffc11d5c55e59d23790ad526b68e5bca4f030cb6a94e6136280866dd

ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="harbor-nginx-photon" \
      org.opencontainers.image.description="Harbor nginx image based on VMware Photon OS 5.0 (multi-arch rebuild of goharbor/nginx-photon)" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/goharbor/harbor" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

RUN tdnf install -y nginx shadow >> /dev/null \
    && tdnf clean all \
    && groupmod -g 10000 nginx \
    && usermod -g 10000 -u 10000 -d /home/nginx -s /bin/bash nginx \
    && chown -R nginx:nginx /etc/nginx \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME /var/cache/nginx /var/log/nginx /run

STOPSIGNAL SIGQUIT

HEALTHCHECK CMD curl --fail -s http://localhost:8080 || exit 1

USER nginx

CMD ["nginx", "-g", "daemon off;"]
