FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

ENV LANG "en_US.UTF-8"
ENV LANGUAGE "en_US:en"
ENV LC_ALL "en_US.UTF-8"
ENV JAVA_HOME "/opt/graalvm"
ENV GRAALVM_HOME "/opt/graalvm"

# Note: graalvm-ce-builds releases are available up to 22.3.x.
# For newer GraalVM, migrate to Oracle GraalVM or GraalVM for JDK.
ARG GRAALVM_VERSION=22.3.3
ARG JAVA_VERSION=java17
ARG GRAALVM_PKG=https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-$GRAALVM_VERSION/graalvm-ce-$JAVA_VERSION-GRAALVM_ARCH-$GRAALVM_VERSION.tar.gz
ARG TARGETPLATFORM

RUN microdnf install -y tar gzip gcc glibc-devel zlib-devel shadow-utils unzip gcc-c++ glibc-langpack-en
RUN groupadd -r quarkus -g 1001 && useradd -u 1001 -r -g 1001 -m -d /home/quarkus -s /sbin/nologin -c "Quarkus user" quarkus
RUN set -eux \
 && if [ "$TARGETPLATFORM" == "linux/amd64" ]; then GRAALVM_PKG=${GRAALVM_PKG/GRAALVM_ARCH/linux-amd64}; fi \
 && if [ "$TARGETPLATFORM" == "linux/arm64" ]; then GRAALVM_PKG=${GRAALVM_PKG/GRAALVM_ARCH/linux-aarch64}; fi \
 && curl --fail --silent --location --retry 3 ${GRAALVM_PKG} \
 | gunzip | tar x -C /opt/ && \
 mv /opt/graalvm-ce-${JAVA_VERSION}-${GRAALVM_VERSION} /opt/graalvm && \
 /opt/graalvm/bin/gu --auto-yes install native-image
