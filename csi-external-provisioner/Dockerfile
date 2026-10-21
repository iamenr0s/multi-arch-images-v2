FROM golang:1.27-alpine@sha256:f2c872bcee949b7be9c490efd02b48a8a2fbf947cdf533f1c58525ec9d8170fd AS builder
ARG VERSION=v5.1.0
ARG TARGETPLATFORM
WORKDIR /go/src/github.com/kubernetes-csi/external-provisioner/
RUN apk add --no-cache git make bash
RUN git clone --depth 1 -b "${VERSION}" https://github.com/kubernetes-csi/external-provisioner.git . \
 && GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d '/') CGO_ENABLED=0 make build

FROM gcr.io/distroless/static:nonroot@sha256:516757106de35205efb70b91ba03f6f1298424a0678c603255cf2852a7000087
WORKDIR /
COPY --from=builder /go/src/github.com/kubernetes-csi/external-provisioner/bin/csi-provisioner /csi-provisioner
ENTRYPOINT ["/csi-provisioner"]
