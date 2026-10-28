# Stage 1: Clone upstream source
FROM alpine:3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a AS source
ARG POSTA_REF=main
RUN apk add --no-cache git
RUN git clone --depth 1 --branch ${POSTA_REF} https://github.com/goposta/posta /app

# Stage 2: Build UI
FROM node:26-alpine@sha256:40cd011b55415bc894e45b02fdd5a5dfde056921b7d23a64c74f80497af48797 AS ui-builder
WORKDIR /app/web
COPY --from=source /app/web/package.json /app/web/package-lock.json ./
RUN npm ci
COPY --from=source /app/web/ .
RUN npm run build

# Stage 3: Build Go binary
FROM golang:1.27-alpine@sha256:d200d2dd76b03a99b52651fd1325aff7dcd35422c35c01bac56571b0507f3deb AS builder
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
FROM alpine:3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a
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
