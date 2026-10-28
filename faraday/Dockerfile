# Stage 1: Clone upstream source
FROM alpine:3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a AS source
ARG FARADAY_REF=master
RUN apk add --no-cache git \
    && git clone --depth 1 --branch ${FARADAY_REF} https://github.com/infobyte/faraday /app

# Stage 2: Runtime
FROM python:3.14-slim-bookworm@sha256:516b51cb9db2ef061e465c803e50f64361b82cefd91e525b889b967b83e83527
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

COPY --from=ghcr.io/astral-sh/uv:0.13.6@sha256:af22a52f5eafef3d78e551599d405c02df61919d18028f0cea8eda93bc9986d0 /uv /usr/local/bin/uv

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
