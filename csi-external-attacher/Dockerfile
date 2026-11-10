FROM golang:1.27-alpine@sha256:eb61c3873c97416fff0116553fff65d67a3549f72e11d9758849a689cdd8b523 AS builder
ARG VERSION=v4.7.0
ARG TARGETPLATFORM
WORKDIR /go/src/github.com/kubernetes-csi/external-attacher/
RUN apk add --no-cache git make bash
RUN git clone --depth 1 -b "${VERSION}" https://github.com/kubernetes-csi/external-attacher.git . \
 && GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d '/') CGO_ENABLED=0 make build

FROM gcr.io/distroless/static:nonroot@sha256:25ac8f0c3b2334a9eb05452266bd4697864a8c8ef0ef71e5e6480d7f92868329
COPY --from=builder /go/src/github.com/kubernetes-csi/external-attacher/bin/csi-attacher /csi-attacher
ENTRYPOINT ["/csi-attacher"]
