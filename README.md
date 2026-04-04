# multi-arch-images-v2

Multi-architecture (amd64 + arm64) container images built with Podman and published to Quay.io and Docker Hub via GitHub Actions.

## Images

| App | Quay.io | Docker Hub | Notes |
|---|---|---|---|
| baseimage | [![Quay](https://img.shields.io/badge/quay.io-iamenr0s%2Fbaseimage-blue?logo=redhat)](https://quay.io/repository/iamenr0s/baseimage) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/baseimage?logo=docker)](https://hub.docker.com/r/iamenr0s/baseimage) | Debian bookworm-slim base with runit, syslog-ng, sshd, cron |
| csi-external-attacher | [![Quay](https://img.shields.io/badge/quay.io-iamenr0s%2Fcsi--external--attacher-blue?logo=redhat)](https://quay.io/repository/iamenr0s/csi-external-attacher) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/csi-external-attacher?logo=docker)](https://hub.docker.com/r/iamenr0s/csi-external-attacher) | Kubernetes CSI sidecar |
| csi-external-provisioner | [![Quay](https://img.shields.io/badge/quay.io-iamenr0s%2Fcsi--external--provisioner-blue?logo=redhat)](https://quay.io/repository/iamenr0s/csi-external-provisioner) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/csi-external-provisioner?logo=docker)](https://hub.docker.com/r/iamenr0s/csi-external-provisioner) | Kubernetes CSI sidecar |
| csi-node-driver-registrar | [![Quay](https://img.shields.io/badge/quay.io-iamenr0s%2Fcsi--node--driver--registrar-blue?logo=redhat)](https://quay.io/repository/iamenr0s/csi-node-driver-registrar) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/csi-node-driver-registrar?logo=docker)](https://hub.docker.com/r/iamenr0s/csi-node-driver-registrar) | Kubernetes CSI sidecar |
| docker-ansible-ubuntu2004 | [![Quay](https://img.shields.io/badge/quay.io-iamenr0s%2Fdocker--ansible--ubuntu2004-blue?logo=redhat)](https://quay.io/repository/iamenr0s/docker-ansible-ubuntu2004) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/docker-ansible-ubuntu2004?logo=docker)](https://hub.docker.com/r/iamenr0s/docker-ansible-ubuntu2004) | Ansible test environment |
| docker-debian-devel | [![Quay](https://img.shields.io/badge/quay.io-iamenr0s%2Fdocker--debian--devel-blue?logo=redhat)](https://quay.io/repository/iamenr0s/docker-debian-devel) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/docker-debian-devel?logo=docker)](https://hub.docker.com/r/iamenr0s/docker-debian-devel) | Debian dev toolchain |
| github-action-molecule | [![Quay](https://img.shields.io/badge/quay.io-iamenr0s%2Fgithub--action--molecule-blue?logo=redhat)](https://quay.io/repository/iamenr0s/github-action-molecule) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/github-action-molecule?logo=docker)](https://hub.docker.com/r/iamenr0s/github-action-molecule) | Fedora 41 + Molecule |
| kibana | [![Quay](https://img.shields.io/badge/quay.io-iamenr0s%2Fkibana-blue?logo=redhat)](https://quay.io/repository/iamenr0s/kibana) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/kibana?logo=docker)](https://hub.docker.com/r/iamenr0s/kibana) | Kibana 9.3.2 (AlmaLinux 9) |
| motioneye | [![Quay](https://img.shields.io/badge/quay.io-iamenr0s%2Fmotioneye-blue?logo=redhat)](https://quay.io/repository/iamenr0s/motioneye) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/motioneye?logo=docker)](https://hub.docker.com/r/iamenr0s/motioneye) | MotionEye on Debian bookworm-slim |
| packer-build-qemu | [![Quay](https://img.shields.io/badge/quay.io-iamenr0s%2Fpacker--build--qemu-blue?logo=redhat)](https://quay.io/repository/iamenr0s/packer-build-qemu) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/packer-build-qemu?logo=docker)](https://hub.docker.com/r/iamenr0s/packer-build-qemu) | Packer + QEMU (Alpine 3.21) |
| posta | [![Quay](https://img.shields.io/badge/quay.io-iamenr0s%2Fposta-blue?logo=redhat)](https://quay.io/repository/iamenr0s/posta) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/posta?logo=docker)](https://hub.docker.com/r/iamenr0s/posta) | Self-hosted email platform (built from source) |
| ubi-quarkus-native-image | [![Quay](https://img.shields.io/badge/quay.io-iamenr0s%2Fubi--quarkus--native--image-blue?logo=redhat)](https://quay.io/repository/iamenr0s/ubi-quarkus-native-image) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/ubi-quarkus-native-image?logo=docker)](https://hub.docker.com/r/iamenr0s/ubi-quarkus-native-image) | GraalVM native image builder |

### Tags

Every build produces:
- `latest` — most recent build
- `<7-char-sha>` — short SHA of this repo, traces to the exact Dockerfile version

## How Builds Work

- **On push:** Any change to `<app>/` triggers a rebuild of that app only.
- **Monthly:** First of each month, all apps rebuild (picks up base image and upstream patches).
- **Manual:** Use the "Run workflow" button in GitHub Actions.

Builds use QEMU emulation on a single `ubuntu-24.04` runner. Both amd64 and arm64 variants are pushed as a single manifest list.

## Required GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret | Value |
|---|---|
| `QUAY_USERNAME` | Your Quay.io username or robot account name |
| `QUAY_PASSWORD` | Your Quay.io password or robot token |
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Your Docker Hub access token |

## Adding a New App

1. Create `<app>/Dockerfile` — use multi-stage builds; keep the runtime image minimal.
2. Copy `.github/workflows/posta.yml` to `.github/workflows/<app>.yml`.
3. Replace all occurrences of `posta` with `<app>` in the workflow file.
4. If the app clones upstream source, add a version-fetching step (see `posta.yml` for reference).
5. Add the image to the table above.
