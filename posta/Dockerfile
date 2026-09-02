# Stage 1: Clone upstream source
FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS source
ARG POSTA_REF=main
RUN apk add --no-cache git
RUN git clone --depth 1 --branch ${POSTA_REF} https://github.com/goposta/posta /app

# Stage 2: Build UI
FROM node:24-alpine@sha256:e67514e5d0f6c46656005e1b693b2ec9d52e80b641307de684d4a015ba7a4eaf AS ui-builder
WORKDIR /app/web
COPY --from=source /app/web/package.json /app/web/package-lock.json ./
RUN npm ci
COPY --from=source /app/web/ .
RUN npm run build

# Stage 3: Build Go binary
FROM golang:1.27-alpine@sha256:26402d86be3d72e6a9410afa0108f03529f51f0c1b5eb7f503d0bc44cc7857ac AS builder
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
