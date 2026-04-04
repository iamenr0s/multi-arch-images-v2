# multi-arch-images-v2

Multi-architecture (amd64 + arm64) container images built with Podman and published to Quay.io and Docker Hub via GitHub Actions.

## Images

| App | Quay.io | Docker Hub | Notes |
|---|---|---|---|
| baseimage | `quay.io/iamenr0s/baseimage` | `docker.io/iamenr0s/baseimage` | Debian bookworm-slim base with runit, syslog-ng, sshd, cron |
| csi-external-attacher | `quay.io/iamenr0s/csi-external-attacher` | `docker.io/iamenr0s/csi-external-attacher` | Kubernetes CSI sidecar |
| csi-external-provisioner | `quay.io/iamenr0s/csi-external-provisioner` | `docker.io/iamenr0s/csi-external-provisioner` | Kubernetes CSI sidecar |
| csi-node-driver-registrar | `quay.io/iamenr0s/csi-node-driver-registrar` | `docker.io/iamenr0s/csi-node-driver-registrar` | Kubernetes CSI sidecar |
| docker-ansible-ubuntu2004 | `quay.io/iamenr0s/docker-ansible-ubuntu2004` | `docker.io/iamenr0s/docker-ansible-ubuntu2004` | Ansible test environment |
| docker-debian-devel | `quay.io/iamenr0s/docker-debian-devel` | `docker.io/iamenr0s/docker-debian-devel` | Debian dev toolchain |
| github-action-molecule | `quay.io/iamenr0s/github-action-molecule` | `docker.io/iamenr0s/github-action-molecule` | Fedora 41 + Molecule |
| kibana | `quay.io/iamenr0s/kibana` | `docker.io/iamenr0s/kibana` | Kibana 9.3.2 (AlmaLinux 9) |
| motioneye | `quay.io/iamenr0s/motioneye` | `docker.io/iamenr0s/motioneye` | MotionEye on Debian bookworm-slim |
| packer-build-qemu | `quay.io/iamenr0s/packer-build-qemu` | `docker.io/iamenr0s/packer-build-qemu` | Packer + QEMU (Alpine 3.21) |
| posta | `quay.io/iamenr0s/posta` | `docker.io/iamenr0s/posta` | Self-hosted email platform (built from source) |
| ubi-quarkus-native-image | `quay.io/iamenr0s/ubi-quarkus-native-image` | `docker.io/iamenr0s/ubi-quarkus-native-image` | GraalVM native image builder |

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
