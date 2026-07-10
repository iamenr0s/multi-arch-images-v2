# Stage 1: Clone upstream source
FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS source
ARG POSTA_REF=main
RUN apk add --no-cache git
RUN git clone --depth 1 --branch ${POSTA_REF} https://github.com/goposta/posta /app

# Stage 2: Build UI
FROM node:24-alpine@sha256:a0b9bf06e4e6193cf7a0f58816cc935ff8c2a908f81e6f1a95432d679c54fbfd AS ui-builder
WORKDIR /app/web
COPY --from=source /app/web/package.json /app/web/package-lock.json ./
RUN npm ci
COPY --from=source /app/web/ .
RUN npm run build

# Stage 3: Build Go binary
FROM golang:1.26-alpine@sha256:0178a641fbb4858c5f1b48e34bdaabe0350a330a1b1149aabd498d0699ff5fb2 AS builder
ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown
WORKDIR /app
COPY --from=source /app/go.mod /app/go.sum ./
RUN go mod download
COPY --from=source /app/cmd/ cmd/
COPY --from=source /app/internal/ internal/
RUN CGO_ENABLED=0 go build \
    -ldflags "-s -w \
      -X 'github.com/goposta/posta/internal/config.Version=${VERSION}' \
      -X 'github.com/goposta/posta/internal/config.CommitID=${COMMIT}' \
      -X 'github.com/goposta/posta/internal/config.BuildDate=${BUILD_DATE}'" \
    -o /bin/posta ./cmd/posta

# Stage 4: Runtime
FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b
ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown
LABEL org.opencontainers.image.title="posta" \
      org.opencontainers.image.description="Posta is a self-hosted email delivery platform" \
      org.opencontainers.image.licenses="Apache" \
      org.opencontainers.image.source="https://github.com/goposta/posta" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"
RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S posta && adduser -S posta -G posta
COPY --from=builder /bin/posta /bin/posta
RUN ln -s /bin/posta /posta
COPY --from=ui-builder /app/web/dist /app/web/dist
ENV POSTA_WEB_DIR=/app/web/dist
USER posta
EXPOSE 9000
ENTRYPOINT ["/bin/posta"]
