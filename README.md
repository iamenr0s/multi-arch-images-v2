# multi-arch-images-v2

Multi-architecture (amd64 + arm64) container images built with Podman and published to Quay.io and Docker Hub via GitHub Actions.

## Images

| App | Quay.io | Docker Hub |
|---|---|---|
| posta | `quay.io/iamenr0s/posta` | `docker.io/iamenr0s/posta` |

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

1. Create `<app>/Dockerfile` — clone upstream source in Stage 1 using an `APP_REF` build arg, build in subsequent stages, minimal runtime in the final stage.
2. Copy `.github/workflows/posta.yml` to `.github/workflows/<app>.yml`.
3. Replace all occurrences of `posta` with `<app>` in the workflow file.
4. Update the upstream GitHub API URL and build args to match the new app.
5. Add the image to the table above in this README.

## Apps

### posta

[posta](https://github.com/goposta/posta) — self-hosted email delivery platform (Go backend + Node.js frontend).

- Port: `9000`
- Runs as: non-root user `posta`
- Build: clones upstream source at build time using `POSTA_REF` (latest release tag), compiles Go binary and Node.js UI
