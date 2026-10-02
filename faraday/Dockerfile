# Stage 1: Clone upstream source
FROM alpine:3.24@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6 AS source
ARG FARADAY_REF=main
RUN apk add --no-cache git \
    && git clone --depth 1 --branch ${FARADAY_REF} https://github.com/infobyte/faraday /app

# Stage 2: Runtime
FROM python:3.14-slim-bookworm@sha256:c8137f4c460908c8763f281c8f22c431eb5c538514ba9553fc3a89c06b7cfb88
ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown
LABEL org.opencontainers.image.title="faraday" \
      org.opencontainers.image.description="Faraday is a collaborative penetration test and vulnerability management platform" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.source="https://github.com/infobyte/faraday" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

WORKDIR /src

COPY --from=source /app/pyproject.toml /app/uv.lock ./
COPY --from=source /app/docker/entrypoint.sh /entrypoint.sh
COPY --from=source /app/docker/server.ini /docker_server.ini

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates python3-dev build-essential libgdk-pixbuf2.0-0 \
      libpq-dev libsasl2-dev libldap2-dev libssl-dev libmagic1 redis-tools netcat-traditional \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* \
    && chmod +x /entrypoint.sh

COPY --from=ghcr.io/astral-sh/uv:0.12.22@sha256:f513a91fc62fe7c17567eee97230dd198e43edb8a9fbecca843714a4358fe1bc /uv /usr/local/bin/uv

RUN uv sync --frozen --no-dev --no-cache --no-editable --no-install-project

COPY --from=source /app /src

RUN uv sync --frozen --no-dev --no-cache --no-editable

ENV PATH="/src/.venv/bin:$PATH"

WORKDIR /home/faraday

RUN mkdir -p \
    /home/faraday/.faraday/config \
    /home/faraday/.faraday/logs \
    /home/faraday/.faraday/session \
    /home/faraday/.faraday/storage

ENV PYTHONUNBUFFERED=1
ENV FARADAY_HOME=/home/faraday

EXPOSE 5985

ENTRYPOINT ["/entrypoint.sh"]
