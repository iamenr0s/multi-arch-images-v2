FROM golang:1.27-alpine@sha256:d200d2dd76b03a99b52651fd1325aff7dcd35422c35c01bac56571b0507f3deb AS builder
ARG VERSION=v4.7.0
ARG TARGETPLATFORM
WORKDIR /go/src/github.com/kubernetes-csi/external-attacher/
RUN apk add --no-cache git make bash
RUN git clone --depth 1 -b "${VERSION}" https://github.com/kubernetes-csi/external-attacher.git . \
 && GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d '/') CGO_ENABLED=0 make build

FROM gcr.io/distroless/static:nonroot@sha256:18f4cc26c9ffa7f20a359298be7deadac5c607c8e03a02b8119f1a5fc2f82c99
COPY --from=builder /go/src/github.com/kubernetes-csi/external-attacher/bin/csi-attacher /csi-attacher
ENTRYPOINT ["/csi-attacher"]
