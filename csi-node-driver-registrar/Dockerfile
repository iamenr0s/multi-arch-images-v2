FROM golang:1.26-alpine@sha256:0178a641fbb4858c5f1b48e34bdaabe0350a330a1b1149aabd498d0699ff5fb2 AS builder
ARG VERSION=v2.12.0
ARG TARGETPLATFORM
WORKDIR /go/src/github.com/kubernetes-csi/node-driver-registrar/
RUN apk add --no-cache git make bash
RUN git clone --depth 1 -b "${VERSION}" https://github.com/kubernetes-csi/node-driver-registrar.git . \
 && GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d '/') CGO_ENABLED=0 make build

FROM gcr.io/distroless/static:nonroot@sha256:f7f8f729987ad0fdf6b05eeeae94b26e6a0f613bdf46feea7fc40f7bd72953e6
WORKDIR /
COPY --from=builder /go/src/github.com/kubernetes-csi/node-driver-registrar/bin/csi-node-driver-registrar /csi-node-driver-registrar
ENTRYPOINT ["/csi-node-driver-registrar"]
