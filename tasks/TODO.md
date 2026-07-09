# CI/CD Hardening — team audit follow-up (2026-07-10)

Source: three-agent audit (deployment-engineer, devops-troubleshooter, security-auditor).
User approved items 1–4.

- [x] 1. binfmt re-registration before arm64 build in exposed workflows
      (harbor-core, harbor-jobservice, harbor-exporter, harbor-trivy-adapter, harbor-portal)
- [x] 2. Retries: `--retry 3 --retry-all-errors` on upstream GH API curls;
      3-attempt retry loop with backoff around every `podman manifest push` (all 24 workflows)
- [x] 3. Download integrity verification in Dockerfiles:
      - kibana: Kibana tarball (.sha512), Node (SHASUMS256.txt), dumb-init (pinned sha256)
      - packer-build-qemu: HashiCorp SHA256SUMS
      - harbor-trivy-adapter: trivy checksums.txt
      - harbor-core: go-swagger sha256sum.txt
      - ubi-quarkus-native-image: GraalVM .sha256
      - github-action-molecule: ADD URLs pinned to containers/image_build commit 9555962
- [x] 4. `concurrency` group (cancel-in-progress) in all 24 workflows

## Review

- 30 files changed (24 workflows + 6 Dockerfiles), no behavior change on the happy path.
- Verified: all 24 workflows parse as YAML; retry function tested (success / recover-after-2 /
  fail-after-3); packer, swagger, and trivy checksum pipelines executed end-to-end against real
  upstream artifacts (all OK); kibana/node/graalvm checksum-file formats and pinned
  image_build URLs confirmed reachable.
- Deliberately NOT done (out of scope, from the audit backlog): reusable workflow refactor,
  action SHA-pinning + base-image digest pinning via Renovate, `FROM --platform` builder
  pinning (unsafe with vanilla podman — no auto-injected BUILDPLATFORM), chmod 755 /cmd.sh,
  USER in ubi-quarkus/motioneye, layer caching.
