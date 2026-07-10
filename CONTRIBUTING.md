# Contributing

Thanks for taking the time to contribute to `multi-arch-images-v2`!

## Getting started

1. Fork the repository and create your branch from `main`.
2. You need Podman (or Docker) installed locally; cross-arch builds additionally need QEMU/binfmt.

## Making changes

- Keep changes small and focused — one topic per pull request.
- Each app lives in its own directory with a `Dockerfile` and a matching workflow in `.github/workflows/<app>.yml`.
- Follow the existing conventions — multi-stage builds, checksum-verified downloads, non-root runtime users where possible. See `CLAUDE.md` for the full conventions and known platform-specific issues.

## Testing

Before opening a pull request, make sure the affected image builds (build context is the app directory):

```bash
podman build --platform linux/amd64 -f <app>/Dockerfile <app>/
```

CI builds every image for `linux/amd64` and `linux/arm64` — changes must not break either architecture. The arm64 leg runs under QEMU emulation, so anything that compiles at build time will be slow there but must still succeed.

## Adding a new app

1. Create `<app>/Dockerfile`.
2. Copy `.github/workflows/kibana.yml` (simple) or `posta.yml` (with upstream version fetch) to `.github/workflows/<app>.yml` and replace the app references.
3. Add the app to the CIS scan matrix in `.github/workflows/cis-scan.yml`.
4. Add the image row to the table in `README.md`.

## Submitting a pull request

1. Ensure the affected image(s) build locally.
2. Fill in the pull request template.
3. A maintainer will review your PR; CI must be green before merge.

## Reporting bugs and requesting features

Use the issue templates — they ask for the details (image, tag, architecture, registry) needed to reproduce a problem. For security vulnerabilities, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating you agree to abide by it.
