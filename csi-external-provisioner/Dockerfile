FROM golang:1.27-alpine@sha256:4c9fe60190a2a3350ddc51de80d0224b8a6698d12bdfc999fee45ea9d6c46dbc AS builder
ARG VERSION=v5.1.0
ARG TARGETPLATFORM
WORKDIR /go/src/github.com/kubernetes-csi/external-provisioner/
RUN apk add --no-cache git make bash
RUN git clone --depth 1 -b "${VERSION}" https://github.com/kubernetes-csi/external-provisioner.git . \
 && GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d '/') CGO_ENABLED=0 make build

FROM gcr.io/distroless/static:nonroot@sha256:1c2c046bc09ed40fad370b599a0b1ae7987f55b01e247cf27a7c27cd97e5bbc7
WORKDIR /
COPY --from=builder /go/src/github.com/kubernetes-csi/external-provisioner/bin/csi-provisioner /csi-provisioner
ENTRYPOINT ["/csi-provisioner"]
