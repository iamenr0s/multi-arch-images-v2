# Multi-Arch Container Images Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a multi-arch (amd64 + arm64) container image for posta using Podman and publish it to Quay.io and Docker Hub via GitHub Actions.

**Architecture:** Each app lives in its own directory with a standalone Dockerfile that clones upstream source at build time. A dedicated GitHub Actions workflow per app triggers on directory changes and monthly, builds both architectures using QEMU emulation on a single runner, and pushes a Podman manifest list to both registries.

**Tech Stack:** Podman 4.x, QEMU binfmt, GitHub Actions, Quay.io, Docker Hub, Go 1.26, Node 22, Alpine 3.21.

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `posta/Dockerfile` | Create | 4-stage build: clone → UI → Go binary → runtime |
| `.github/workflows/posta.yml` | Create | Build + push workflow with QEMU |
| `README.md` | Modify | Document repo usage, secrets, how to add apps |

---

## Task 1: posta Dockerfile

**Files:**
- Create: `posta/Dockerfile`

- [ ] **Step 1: Create the Dockerfile**

Create `posta/Dockerfile` with this exact content:

```dockerfile
# Stage 1: Clone upstream source
FROM alpine:3.21 AS source
RUN apk add --no-cache git
RUN git clone https://github.com/goposta/posta /app

# Stage 2: Build UI
FROM node:22-alpine AS ui-builder
WORKDIR /app/web
COPY --from=source /app/web/package.json /app/web/package-lock.json ./
RUN npm ci
COPY --from=source /app/web/ .
RUN npm run build

# Stage 3: Build Go binary
FROM golang:1.26-alpine AS builder
ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown
WORKDIR /app
COPY --from=source /app/go.mod /app/go.sum ./
RUN go mod download
COPY --from=source /app/cmd/ cmd/
COPY --from=source /app/internal/ internal/
RUN CGO_ENABLED=0 go build \
    -ldflags "-s -w \
      -X 'github.com/goposta/posta/internal/config.Version=${VERSION}' \
      -X 'github.com/goposta/posta/internal/config.CommitID=${COMMIT}' \
      -X 'github.com/goposta/posta/internal/config.BuildDate=${BUILD_DATE}'" \
    -o /bin/posta ./cmd/posta

# Stage 4: Runtime
FROM alpine:3.21
ARG VERSION=dev
ARG COMMIT=unknown
LABEL org.opencontainers.image.title="posta" \
      org.opencontainers.image.description="Posta is a self-hosted email delivery platform" \
      org.opencontainers.image.licenses="Apache" \
      org.opencontainers.image.source="https://github.com/goposta/posta" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}"
RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S posta && adduser -S posta -G posta
COPY --from=builder /bin/posta /bin/posta
RUN ln -s /bin/posta /posta
COPY --from=ui-builder /app/web/dist /app/web/dist
ENV POSTA_WEB_DIR=/app/web/dist
USER posta
EXPOSE 9000
ENTRYPOINT ["/bin/posta"]
```

- [ ] **Step 2: Verify Dockerfile syntax with hadolint**

```bash
docker run --rm -i hadolint/hadolint < posta/Dockerfile
```

Expected: No output (clean). If hadolint is not available locally, skip — the workflow will catch issues.

- [ ] **Step 3: Commit**

```bash
git add posta/Dockerfile
git commit -m "feat: add posta Dockerfile (4-stage multi-arch build)"
```

---

## Task 2: GitHub Actions Workflow

**Files:**
- Create: `.github/workflows/posta.yml`

- [ ] **Step 1: Create the workflow directory**

```bash
mkdir -p .github/workflows
```

- [ ] **Step 2: Create `.github/workflows/posta.yml`**

```yaml
name: Build and Push posta

on:
  push:
    branches:
      - main
    paths:
      - 'posta/**'
  schedule:
    - cron: '0 0 1 * *'
  workflow_dispatch:

jobs:
  build:
    name: Build multi-arch image
    runs-on: ubuntu-24.04

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Get upstream posta version info
        id: upstream
        run: |
          LATEST_TAG=$(curl -s https://api.github.com/repos/goposta/posta/releases/latest | jq -r '.tag_name // "dev"')
          LATEST_COMMIT=$(curl -s https://api.github.com/repos/goposta/posta/commits/main | jq -r '.sha' | cut -c1-7)
          BUILD_DATE=$(date -u +%Y-%m-%d)
          echo "version=${LATEST_TAG}" >> "$GITHUB_OUTPUT"
          echo "commit=${LATEST_COMMIT}" >> "$GITHUB_OUTPUT"
          echo "build_date=${BUILD_DATE}" >> "$GITHUB_OUTPUT"

      - name: Set short SHA tag
        id: tags
        run: |
          SHORT_SHA=$(echo "${{ github.sha }}" | cut -c1-7)
          echo "short_sha=${SHORT_SHA}" >> "$GITHUB_OUTPUT"

      - name: Login to Quay.io
        uses: docker/login-action@v3
        with:
          registry: quay.io
          username: ${{ secrets.QUAY_USERNAME }}
          password: ${{ secrets.QUAY_PASSWORD }}

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          registry: docker.io
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build amd64
        run: |
          podman build \
            --platform linux/amd64 \
            --manifest posta \
            --build-arg VERSION=${{ steps.upstream.outputs.version }} \
            --build-arg COMMIT=${{ steps.upstream.outputs.commit }} \
            --build-arg BUILD_DATE=${{ steps.upstream.outputs.build_date }} \
            -f posta/Dockerfile \
            posta/

      - name: Build arm64
        run: |
          podman build \
            --platform linux/arm64 \
            --manifest posta \
            --build-arg VERSION=${{ steps.upstream.outputs.version }} \
            --build-arg COMMIT=${{ steps.upstream.outputs.commit }} \
            --build-arg BUILD_DATE=${{ steps.upstream.outputs.build_date }} \
            -f posta/Dockerfile \
            posta/

      - name: Push to Quay.io
        run: |
          podman manifest push --all posta \
            quay.io/iamenr0s/posta:latest
          podman manifest push --all posta \
            quay.io/iamenr0s/posta:${{ steps.tags.outputs.short_sha }}

      - name: Push to Docker Hub
        run: |
          podman manifest push --all posta \
            docker.io/iamenr0s/posta:latest
          podman manifest push --all posta \
            docker.io/iamenr0s/posta:${{ steps.tags.outputs.short_sha }}
```

- [ ] **Step 3: Validate workflow YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/posta.yml'))" && echo "YAML valid"
```

Expected output: `YAML valid`

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/posta.yml
git commit -m "feat: add GitHub Actions workflow for posta multi-arch build"
```

---

## Task 3: Update README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace README.md with full documentation**

```markdown
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
- **Monthly:** First of each month, all apps rebuild (picks up base image patches).
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

1. Create `<app>/Dockerfile` — clone upstream source in Stage 1, build in Stage 2+, minimal runtime in the final stage.
2. Copy `.github/workflows/posta.yml` to `.github/workflows/<app>.yml`.
3. Replace all occurrences of `posta` with `<app>` in the workflow file.
4. Update the upstream source URL and build args to match the new app.
5. Add the image to the table above.

## Apps

### posta

[posta](https://github.com/goposta/posta) — self-hosted email delivery platform (Go + Node.js frontend).

- Port: `9000`
- Runs as: non-root user `posta`
- Build: clones upstream source at build time, compiles Go binary + Node UI
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README with usage, secrets, and how to add apps"
```

---

## Task 4: Verify First CI Run

- [ ] **Step 1: Push to GitHub and watch the Actions run**

```bash
git push origin main
```

Then open: `https://github.com/<your-org>/multi-arch-images-v2/actions`

- [ ] **Step 2: Confirm both arch builds succeed**

Watch the workflow run. Expected: all steps green, including both `Build amd64` and `Build arm64` steps.

- [ ] **Step 3: Verify images on Quay.io**

Open `https://quay.io/repository/iamenr0s/posta` and confirm:
- `latest` tag exists
- `<sha>` tag exists
- The manifest shows both `amd64` and `arm64` variants

- [ ] **Step 4: Verify images on Docker Hub**

Open `https://hub.docker.com/r/iamenr0s/posta/tags` and confirm same tags are present.

- [ ] **Step 5: Pull and verify multi-arch manifest**

```bash
podman manifest inspect quay.io/iamenr0s/posta:latest | jq '.manifests[].platform'
```

Expected output (two entries):
```json
{ "architecture": "amd64", "os": "linux" }
{ "architecture": "arm64", "os": "linux" }
```
