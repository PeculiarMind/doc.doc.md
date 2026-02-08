# Bill of Materials - Debian 12 Development Container

## Base Image
- **Image**: debian:12
- **SHA256**: b877a1a3fdf02469440f1768cf69c9771338a875b7add5e80c45b756c92ac84a
- **Source**: Docker Official Images
- **Verified**: Yes (SHA256 pinning per req_0028)

## Installed Packages

Same package set as Ubuntu, sourced from official Debian 12 repositories:
- bash, git, make, sed, gawk, grep (Core)
- shellcheck, jq (Testing)
- file, coreutils, libimage-exiftool-perl, poppler-utils (CLI tools)
- pandoc (Documentation)
- curl, ca-certificates, sudo (Utilities)

## Verification

All packages verified via:
- Official Debian repositories
- GPG signature verification (apt default)
- HTTPS transport

## Compliance

- ✅ req_0029: Package Integrity
- ✅ req_0028: Base Image Verification
