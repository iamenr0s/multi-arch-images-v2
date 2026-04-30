# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

Builds multi-arch (amd64 + arm64) container images using Podman and publishes them to `quay.io/iamenr0s/` and `docker.io/iamenr0s/` via GitHub Actions. Each app lives in its own directory with a `Dockerfile` and a corresponding workflow in `.github/workflows/<app>.yml`.

## Building Locally

```bash
# Build a single arch locally (no push)
podman build --platform linux/amd64 -f <app>/Dockerfile <app>/

# Build multi-arch manifest (requires QEMU for cross-arch)
podman build --platform linux/amd64 --manifest <app> -f <app>/Dockerfile <app>/
podman build --platform linux/arm64 --manifest <app> -f <app>/Dockerfile <app>/

# Push manifest
podman manifest push --all <app> quay.io/iamenr0s/<app>:latest
```

## Workflow Pattern

All workflows follow the same structure (`kibana.yml` is the simplest reference; `posta.yml` is the reference for apps that fetch upstream versions):

1. Trigger: push to `<app>/`, monthly schedule (`0 0 1 * *`), or manual dispatch
2. QEMU setup for cross-arch emulation on a single `ubuntu-24.04` runner
3. Optional: fetch latest upstream version via GitHub API (authenticated with `github.token`)
4. Build amd64 and arm64 sequentially into a named manifest
5. Push manifest to Quay.io and Docker Hub with `latest` + 7-char SHA tags

**Shell injection prevention:** GitHub Actions context values (`${{ steps.*.outputs.* }}`) are always passed via `env:` blocks, never interpolated directly into `run:` scripts.

**Annotated tag handling:** When fetching upstream versions, check `TAG_TYPE` — if `"tag"`, dereference via `/git/tags/{sha}` to get the actual commit SHA.

## Adding a New App

1. Create `<app>/Dockerfile`
2. Copy `.github/workflows/kibana.yml` (simple) or `posta.yml` (with upstream version fetch) to `.github/workflows/<app>.yml`
3. Replace all `kibana`/`posta` references with `<app>`
4. Add the image to the table in `README.md`

## Dockerfile Conventions

- **Multi-stage builds** — separate build and runtime stages; keep the runtime image minimal
- **Runtime images:** Alpine for Go/Node apps, Debian bookworm-slim for Python/system apps, AlmaLinux 9 for RPM-based apps
- **Non-root:** apps run as a dedicated non-root user where possible
- **Tags:** `latest` + `<7-char-sha>` of this repo (not the upstream app's SHA)

## Known Platform-Specific Issues

- **Debian bookworm-slim:** No `/etc/apt/sources.list` (uses `sources.list.d/`). PEP 668 blocks system-wide pip — use `apt install python3-pip` + `--break-system-packages` in containers.
- **AlmaLinux 9:** `glibc-static` is in the CRB repo (`yum-config-manager --enable crb`). Base image ships `curl-minimal` which conflicts with `curl` — use `yum install --allowerasing`.
- **Elastic tarballs:** `-oss` suffix was dropped after Kibana 7.10.x; use `kibana-${VERSION}-linux-...` for 8.x+.
- **baseimage:** Phusion-style init system (`/sbin/my_init` → runit). `prepare.sh` handles locale and container compatibility setup. Services (syslog-ng, sshd, cron) are optional via `DISABLE_SYSLOG`, `DISABLE_SSH`, `DISABLE_CRON` env vars.

## Required Secrets

`QUAY_USERNAME`, `QUAY_PASSWORD`, `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` — set in **Settings → Secrets and variables → Actions**.
