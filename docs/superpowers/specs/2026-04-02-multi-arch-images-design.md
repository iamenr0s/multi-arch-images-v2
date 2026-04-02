# Multi-Arch Container Images — Design Spec
**Date:** 2026-04-02
**Status:** Approved

---

## Overview

A repository for building and publishing multi-architecture (amd64 + arm64) container images. Images are built with Podman, using QEMU emulation on a single GitHub Actions runner, and pushed to both Quay.io and Docker Hub.

The first application is [posta](https://github.com/goposta/posta) — a self-hosted email delivery platform with a Go backend and Node.js frontend.

---

## Repository Structure

```
multi-arch-images-v2/
├── .github/
│   └── workflows/
│       └── posta.yml          # Triggers on posta/** changes + monthly cron
├── posta/
│   └── Dockerfile             # 4-stage multi-arch build from upstream source
├── docs/
│   └── superpowers/
│       └── specs/
│           └── 2026-04-02-multi-arch-images-design.md
└── README.md
```

Each future application gets its own directory and its own workflow file, keeping builds independently triggerable.

---

## Registries

| Registry | Image |
|---|---|
| Quay.io | `quay.io/iamenr0s/<app>` |
| Docker Hub | `docker.io/iamenr0s/<app>` |

### Image Tags

Every build produces two tags pushed to both registries:
- `latest` — always points to the newest build
- `<7-char git SHA>` — short SHA of **this** repo, traces back to the exact Dockerfile version

---

## Architectures

- `linux/amd64`
- `linux/arm64`

Both built on a single amd64 GitHub Actions runner using QEMU binfmt emulation. A single Podman manifest list is pushed containing both platform variants.

---

## Build Strategy: QEMU Emulation (Single Runner)

**Why:** Most portable approach for a multi-app image repository. Works for any app type (Go, Node, Python, etc.), not just pure-Go. Cost-effective — uses standard GitHub-hosted runners. Build slowness (~3–5x for arm64) is acceptable given the monthly rebuild schedule.

**Alternatives rejected:**
- Native arm64 runners (matrix strategy) — higher cost, more complex manifest merge job
- Go cross-compilation only — doesn't generalize to non-Go apps

---

## posta Dockerfile

4-stage build cloning upstream source at build time:

```
Stage 1 (source)     — alpine: git clone goposta/posta
Stage 2 (ui-builder) — node:22-alpine: npm ci && npm run build
Stage 3 (builder)    — golang:1.26-alpine: CGO_ENABLED=0 go build with version ldflags
Stage 4 (runtime)    — alpine:3.21: non-root user, ca-certificates, tzdata, port 9000
```

**Build args passed by CI:**
| Arg | Source |
|---|---|
| `VERSION` | Latest tag from `goposta/posta` GitHub API |
| `COMMIT` | Latest commit SHA from `goposta/posta` |
| `BUILD_DATE` | Current date at build time (`YYYY-MM-DD`) |

**Runtime details:**
- Non-root user: `posta`
- Exposed port: `9000`
- Env: `POSTA_WEB_DIR=/app/web/dist`
- Entrypoint: `/bin/posta`

---

## GitHub Actions Workflow: posta.yml

### Triggers

| Trigger | Condition |
|---|---|
| `push` | Changes to `posta/**` on `main` |
| `schedule` | `0 0 1 * *` — first of each month, midnight UTC |
| `workflow_dispatch` | Manual trigger |

### Job Steps

1. Checkout this repo
2. Set up QEMU (`docker/setup-qemu-action@v3`)
3. Fetch latest upstream tag + commit from `goposta/posta` GitHub API
4. Login to `quay.io` using secrets
5. Login to `docker.io` using secrets
6. `podman build --platform linux/amd64 --manifest posta` with build args
7. `podman build --platform linux/arm64 --manifest posta` with build args
8. Push manifest (`--all`) to `quay.io/iamenr0s/posta:latest` and `quay.io/iamenr0s/posta:<sha>`
9. Push manifest (`--all`) to `docker.io/iamenr0s/posta:latest` and `docker.io/iamenr0s/posta:<sha>`

### Required GitHub Secrets

| Secret | Purpose |
|---|---|
| `QUAY_USERNAME` | Quay.io username or robot account |
| `QUAY_PASSWORD` | Quay.io password or robot token |
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |

---

## Future Apps

When adding a new application:
1. Create `<app>/Dockerfile` in this repo
2. Create `.github/workflows/<app>.yml` following the same pattern
3. Add registry namespaces as needed (same `iamenr0s` org)
