# multi-arch-images-v2

Multi-architecture (amd64 + arm64) container images built with Podman and published to Quay.io and Docker Hub via GitHub Actions.

## Images

| App | Quay.io | Docker Hub | Notes |
|---|---|---|---|
| baseimage | [![Quay Pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fquay.io%2Fapi%2Fv1%2Frepository%2Fiamenr0s%2Fbaseimage&query=%24.pull_count&label=quay%20pulls&logo=redhat&color=red)](https://quay.io/repository/iamenr0s/baseimage) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/baseimage?logo=docker)](https://hub.docker.com/r/iamenr0s/baseimage) | Debian bookworm-slim base with runit, syslog-ng, sshd, cron |
| csi-external-attacher | [![Quay Pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fquay.io%2Fapi%2Fv1%2Frepository%2Fiamenr0s%2Fcsi-external-attacher&query=%24.pull_count&label=quay%20pulls&logo=redhat&color=red)](https://quay.io/repository/iamenr0s/csi-external-attacher) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/csi-external-attacher?logo=docker)](https://hub.docker.com/r/iamenr0s/csi-external-attacher) | Kubernetes CSI sidecar |
| csi-external-provisioner | [![Quay Pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fquay.io%2Fapi%2Fv1%2Frepository%2Fiamenr0s%2Fcsi-external-provisioner&query=%24.pull_count&label=quay%20pulls&logo=redhat&color=red)](https://quay.io/repository/iamenr0s/csi-external-provisioner) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/csi-external-provisioner?logo=docker)](https://hub.docker.com/r/iamenr0s/csi-external-provisioner) | Kubernetes CSI sidecar |
| csi-node-driver-registrar | [![Quay Pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fquay.io%2Fapi%2Fv1%2Frepository%2Fiamenr0s%2Fcsi-node-driver-registrar&query=%24.pull_count&label=quay%20pulls&logo=redhat&color=red)](https://quay.io/repository/iamenr0s/csi-node-driver-registrar) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/csi-node-driver-registrar?logo=docker)](https://hub.docker.com/r/iamenr0s/csi-node-driver-registrar) | Kubernetes CSI sidecar |
| docker-ansible-ubuntu2004 | [![Quay Pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fquay.io%2Fapi%2Fv1%2Frepository%2Fiamenr0s%2Fdocker-ansible-ubuntu2004&query=%24.pull_count&label=quay%20pulls&logo=redhat&color=red)](https://quay.io/repository/iamenr0s/docker-ansible-ubuntu2004) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/docker-ansible-ubuntu2004?logo=docker)](https://hub.docker.com/r/iamenr0s/docker-ansible-ubuntu2004) | Ansible test environment |
| docker-debian-devel | [![Quay Pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fquay.io%2Fapi%2Fv1%2Frepository%2Fiamenr0s%2Fdocker-debian-devel&query=%24.pull_count&label=quay%20pulls&logo=redhat&color=red)](https://quay.io/repository/iamenr0s/docker-debian-devel) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/docker-debian-devel?logo=docker)](https://hub.docker.com/r/iamenr0s/docker-debian-devel) | Debian dev toolchain |
| github-action-molecule | [![Quay Pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fquay.io%2Fapi%2Fv1%2Frepository%2Fiamenr0s%2Fgithub-action-molecule&query=%24.pull_count&label=quay%20pulls&logo=redhat&color=red)](https://quay.io/repository/iamenr0s/github-action-molecule) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/github-action-molecule?logo=docker)](https://hub.docker.com/r/iamenr0s/github-action-molecule) | Fedora 41 + Molecule |
| kibana | [![Quay Pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fquay.io%2Fapi%2Fv1%2Frepository%2Fiamenr0s%2Fkibana&query=%24.pull_count&label=quay%20pulls&logo=redhat&color=red)](https://quay.io/repository/iamenr0s/kibana) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/kibana?logo=docker)](https://hub.docker.com/r/iamenr0s/kibana) | Kibana 9.3.2 (AlmaLinux 9) |
| motioneye | [![Quay Pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fquay.io%2Fapi%2Fv1%2Frepository%2Fiamenr0s%2Fmotioneye&query=%24.pull_count&label=quay%20pulls&logo=redhat&color=red)](https://quay.io/repository/iamenr0s/motioneye) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/motioneye?logo=docker)](https://hub.docker.com/r/iamenr0s/motioneye) | MotionEye on Debian bookworm-slim |
| packer-build-qemu | [![Quay Pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fquay.io%2Fapi%2Fv1%2Frepository%2Fiamenr0s%2Fpacker-build-qemu&query=%24.pull_count&label=quay%20pulls&logo=redhat&color=red)](https://quay.io/repository/iamenr0s/packer-build-qemu) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/packer-build-qemu?logo=docker)](https://hub.docker.com/r/iamenr0s/packer-build-qemu) | Packer + QEMU (Alpine 3.21) |
| posta | [![Quay Pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fquay.io%2Fapi%2Fv1%2Frepository%2Fiamenr0s%2Fposta&query=%24.pull_count&label=quay%20pulls&logo=redhat&color=red)](https://quay.io/repository/iamenr0s/posta) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/posta?logo=docker)](https://hub.docker.com/r/iamenr0s/posta) | Self-hosted email platform (built from source) |
| ubi-quarkus-native-image | [![Quay Pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fquay.io%2Fapi%2Fv1%2Frepository%2Fiamenr0s%2Fubi-quarkus-native-image&query=%24.pull_count&label=quay%20pulls&logo=redhat&color=red)](https://quay.io/repository/iamenr0s/ubi-quarkus-native-image) | [![Docker Pulls](https://img.shields.io/docker/pulls/iamenr0s/ubi-quarkus-native-image?logo=docker)](https://hub.docker.com/r/iamenr0s/ubi-quarkus-native-image) | GraalVM native image builder |

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
