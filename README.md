# multi-arch-images-v2

Multi-architecture (amd64 + arm64) container images built with Podman and published to Quay.io and Docker Hub via GitHub Actions.

## Images

| App | Quay.io | Docker Hub | Notes |
|---|---|---|---|
| baseimage | `quay.io/iamenr0s/baseimage` | `docker.io/iamenr0s/baseimage` | Debian bookworm-slim base |
| csi-external-attacher | `quay.io/iamenr0s/csi-external-attacher` | `docker.io/iamenr0s/csi-external-attacher` | Kubernetes CSI v4.7.0 |
| csi-external-provisioner | `quay.io/iamenr0s/csi-external-provisioner` | `docker.io/iamenr0s/csi-external-provisioner` | Kubernetes CSI v5.1.0 |
| csi-node-driver-registrar | `quay.io/iamenr0s/csi-node-driver-registrar` | `docker.io/iamenr0s/csi-node-driver-registrar` | Kubernetes CSI v2.12.0 |
| docker-ansible-ubuntu2004 | `quay.io/iamenr0s/docker-ansible-ubuntu2004` | `docker.io/iamenr0s/docker-ansible-ubuntu2004` | Ansible test environment |
| docker-debian-devel | `quay.io/iamenr0s/docker-debian-devel` | `docker.io/iamenr0s/docker-debian-devel` | Debian dev toolchain |
| github-action-molecule | `quay.io/iamenr0s/github-action-molecule` | `docker.io/iamenr0s/github-action-molecule` | Fedora 41 + Molecule |
| kibana | `quay.io/iamenr0s/kibana` | `docker.io/iamenr0s/kibana` | Kibana OSS 7.17.28 (AlmaLinux 9) |
| motioneye | `quay.io/iamenr0s/motioneye` | `docker.io/iamenr0s/motioneye` | Debian bookworm-slim |
| packer-build-qemu | `quay.io/iamenr0s/packer-build-qemu` | `docker.io/iamenr0s/packer-build-qemu` | Packer 1.11.2 (Alpine 3.21) |
| posta | `quay.io/iamenr0s/posta` | `docker.io/iamenr0s/posta` | Self-hosted email platform |
| ubi-quarkus-native-image | `quay.io/iamenr0s/ubi-quarkus-native-image` | `docker.io/iamenr0s/ubi-quarkus-native-image` | GraalVM CE 22.3.3 / Java 17 |

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

## Migration Notes

Migrated from [iamenr0s/multi-arch-images](https://github.com/iamenr0s/multi-arch-images). Key changes:

- **Tooling:** `docker buildx` → `podman build --manifest`
- **Runner:** `ubuntu-latest` → `ubuntu-24.04`
- **Registries:** Docker Hub only (`enros/`) → Quay.io + Docker Hub (`iamenr0s/`)
- **Architectures:** amd64 + arm/v7 + arm64 → amd64 + arm64
- **Security:** authenticated GitHub API calls, env-scoped build args, `permissions: contents: read`, `timeout-minutes`
- **Base images updated:** `debian:bullseye` → `debian:bookworm`, `centos:7` → `almalinux:9`, `golang:1.15` → `golang:1.24-alpine`, `alpine:3.11` → `alpine:3.21`, `fedora:39` → `fedora:41`
- **Known limitation:** `ubi-quarkus-native-image` uses GraalVM CE 22.3.3 (last release compatible with the `graalvm-ce-builds` download URL). Newer GraalVM requires migration to Oracle GraalVM distribution.

## Apps

### posta

[posta](https://github.com/goposta/posta) — self-hosted email delivery platform (Go backend + Node.js frontend).

- Port: `9000`
- Runs as: non-root user `posta`
- Build: clones upstream source at build time using `POSTA_REF` (latest release tag), compiles Go binary and Node.js UI
