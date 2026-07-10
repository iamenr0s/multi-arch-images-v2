# CIS Compliance Notes

The [CIS compliance scan workflow](.github/workflows/cis-scan.yml) lints every Dockerfile (hadolint), scans every image for fixed HIGH/CRITICAL CVEs (Trivy), reports against the CIS Docker Benchmark (Trivy compliance), and lints the final images (Dockle). Results land in GitHub code scanning.

## Accepted deviations

These findings are deliberate and ignored in the scan configuration:

| Rule | Deviation | Why |
| ---- | --------- | --- |
| Dockle `CIS-DI-0001` (run as non-root) | `baseimage`, `github-action-molecule`, `motioneye`, `packer-build-qemu`, `harbor-log` run as root | Init systems (phusion runit), rootful podman-in-podman, and syslog collection require root. Images with no such requirement (`harbor-*` services, `kibana`, `posta`) run as dedicated non-root users. |
| Dockle `CIS-DI-0008` (setuid/setgid files) | Base distro setuid binaries kept | Required by the init/system images above; stripping them breaks `su`/`sudo`-dependent tooling. |
| hadolint `DL3008`/`DL3013`/`DL3041` (pin package versions) | Distro packages unpinned | Every monthly rebuild must pull the newest distro packages so published CVE fixes land automatically. Upstream app versions ARE pinned via build args and verified with checksums. |

## CVE policy

- **Fixed CVEs** (a patched package exists): resolved automatically by the monthly rebuild; visible in code scanning until then.
- **Unfixed CVEs**: not reported to code scanning (`ignore-unfixed: true`) to avoid drowning the signal; they appear in the CIS benchmark report step output and resolve when the distro publishes a fix.
