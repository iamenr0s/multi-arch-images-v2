# syntax=docker/dockerfile:1.7

ARG HARBOR_REF=v2.15.0
# Pin to the upstream Makefile's NODEBUILDIMAGE for Angular build compatibility.
ARG NODE_IMAGE=node:16.20.2

#
# Stage 1: builder — Angular production build + swagger JSON + app-swagger-ui.
# Pure-JS output is arch-agnostic, so pin the builder to BUILDPLATFORM regardless
# of the final image's target arch.
#
FROM ${NODE_IMAGE} AS builder

ARG HARBOR_REF
ARG NPM_REGISTRY=https://registry.npmjs.org

# The node:16.18.0 image is based on buildpack-deps:buster-scm, which already
# ships git and ca-certificates. Buster's apt repos have been archived, so
# running apt-get update would 404.

WORKDIR /src
RUN git clone --depth 1 --branch "${HARBOR_REF}" https://github.com/goharbor/harbor.git .

# Mirror upstream layout: drop src/portal into /build_dir alongside the swagger spec
# and the repo LICENSE (needed by the prod build).
WORKDIR /build_dir
RUN cp -a /src/src/portal/. /build_dir/ \
    && cp /src/api/v2.0/swagger.yaml /build_dir/swagger.yaml \
    && cp /src/LICENSE /build_dir/LICENSE

ENV NPM_CONFIG_REGISTRY=${NPM_REGISTRY}

# npm install triggers postinstall (convert-yaml-to-json + ng-swagger-gen).
RUN npm install --unsafe-perm

RUN npm run generate-build-timestamp

RUN node --max_old_space_size=2048 node_modules/@angular/cli/bin/ng build \
        --configuration production

# Convert swagger YAML to JSON for the bundled Swagger UI.
RUN npm install js-yaml@4.1.0 \
    && node -e "const yaml=require('js-yaml');const fs=require('fs');const s=yaml.load(fs.readFileSync('swagger.yaml','utf8'));fs.writeFileSync('swagger.json',JSON.stringify(s));"

RUN cp /build_dir/LICENSE /build_dir/dist/LICENSE

# app-swagger-ui is a separate Angular workspace shipped alongside the portal.
RUN cd app-swagger-ui && npm install --unsafe-perm
RUN cd app-swagger-ui && npm run build

#
# Stage 2: runtime — photon:5.0 + nginx, mirroring upstream harbor-portal-base.
# Runtime nginx.conf is injected by Harbor's deploy-time prepare script; the base
# image just carries nginx and the static assets.
#
FROM photon:5.0

ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="harbor-portal" \
      org.opencontainers.image.description="Harbor web UI (Angular) on Photon OS 5.0 (multi-arch rebuild of goharbor/harbor-portal)" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/goharbor/harbor" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

RUN tdnf install -y nginx shadow >> /dev/null \
    && tdnf clean all \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && groupmod -g 10000 nginx \
    && usermod -g 10000 -u 10000 -d /home/nginx -s /bin/bash nginx \
    && chown -R nginx:nginx /etc/nginx

COPY --from=builder /build_dir/dist                 /usr/share/nginx/html
COPY --from=builder /build_dir/swagger.json         /usr/share/nginx/html/swagger.json
COPY --from=builder /build_dir/app-swagger-ui/dist  /usr/share/nginx/html

VOLUME /var/cache/nginx /var/log/nginx /run

STOPSIGNAL SIGQUIT

HEALTHCHECK CMD curl --fail -s http://localhost:8080 \
        || curl -k --fail -s https://localhost:8443 \
        || exit 1

USER nginx

CMD ["nginx", "-g", "daemon off;"]
