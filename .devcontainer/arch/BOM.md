# Bill of Materials - Arch Linux Development Container

## Base Image
- **Image**: archlinux:latest
- **SHA256**: 67f8d15e5389e54e2e4f60c2b8c09b0a45e1ee4f18ebdd31bac6dbc0a91c6d9a
- **Source**: Docker Official Images
- **Verified**: Yes (SHA256 pinning per req_0028)

## Installed Packages

From official Arch Linux repositories:
- bash, git, make, sed, gawk, grep (Core)
- shellcheck, jq (Testing)
- file, coreutils, perl-image-exiftool, poppler (CLI tools)
- pandoc (Documentation)
- curl, ca-certificates, sudo (Utilities)

## Verification

All packages verified via:
- Official Arch Linux repositories
- GPG signature verification (pacman default)
- HTTPS transport

## Compliance

- ✅ req_0029: Package Integrity
- ✅ req_0028: Base Image Verification
