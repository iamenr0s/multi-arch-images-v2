FROM golang:1.27-alpine@sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414 AS builder
ARG VERSION=v2.12.0
ARG TARGETPLATFORM
WORKDIR /go/src/github.com/kubernetes-csi/node-driver-registrar/
RUN apk add --no-cache git make bash
RUN git clone --depth 1 -b "${VERSION}" https://github.com/kubernetes-csi/node-driver-registrar.git . \
 && GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d '/') CGO_ENABLED=0 make build

FROM gcr.io/distroless/static:nonroot@sha256:e2e927ec666bae08560abb3c55d0659eceabb657f56b6782ab500a9fc7f555e3
WORKDIR /
COPY --from=builder /go/src/github.com/kubernetes-csi/node-driver-registrar/bin/csi-node-driver-registrar /csi-node-driver-registrar
ENTRYPOINT ["/csi-node-driver-registrar"]
