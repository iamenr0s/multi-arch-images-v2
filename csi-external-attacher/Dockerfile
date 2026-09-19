FROM golang:1.27-alpine@sha256:4cb7ac979db5fcc41cae44b2227ba5ab8a51e8807f40d9ba4dee20a0ad960b5b AS builder
ARG VERSION=v4.7.0
ARG TARGETPLATFORM
WORKDIR /go/src/github.com/kubernetes-csi/external-attacher/
RUN apk add --no-cache git make bash
RUN git clone --depth 1 -b "${VERSION}" https://github.com/kubernetes-csi/external-attacher.git . \
 && GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d '/') CGO_ENABLED=0 make build

FROM gcr.io/distroless/static:nonroot@sha256:e2e927ec666bae08560abb3c55d0659eceabb657f56b6782ab500a9fc7f555e3
COPY --from=builder /go/src/github.com/kubernetes-csi/external-attacher/bin/csi-attacher /csi-attacher
ENTRYPOINT ["/csi-attacher"]
