# Bill of Materials - Alpine Linux Generic Development Container

## Base Image
- **Image**: alpine:3.19
- **SHA256**: 6457d53fb065d6f250e1504b9bc42d5b6c65941d57532c072d929dd0628977d0
- **Source**: Docker Official Images
- **Verified**: Yes (SHA256 pinning per req_0028)

## Installed Packages

From official Alpine Linux repositories:
- bash, git, make, sed, gawk, grep (Core)
- shellcheck, jq (Testing)
- file, coreutils, exiftool, poppler-utils (CLI tools)
- pandoc (Documentation)
- curl, ca-certificates, sudo, shadow (Utilities)

## Verification

All packages verified via:
- Official Alpine Linux repositories
- GPG signature verification (apk default)
- HTTPS transport

## Compliance

- ✅ req_0029: Package Integrity
- ✅ req_0028: Base Image Verification

## Notes

Alpine uses musl libc and produces smaller container images (~100MB vs ~450MB Ubuntu).
