# Generic (Alpine) Development Container

Minimal Alpine Linux environment - smallest footprint for generic Linux development.

## Quick Start

```bash
# Open in VS Code
# F1 > "Dev Containers: Reopen in Container" > Select "Generic (Alpine)"
```

## Security Implementation

- ✅ req_0027: Secrets Management - SSH keys mounted read-only, no embedded credentials
- ✅ req_0028: Base Image Verification - SHA256 pinned Alpine official image
- ✅ req_0029: Package Integrity - Official Alpine repos with GPG verification (apk)
- ✅ req_0030: Privilege Restriction - Non-root user (UID 1000), capabilities dropped
- ✅ req_0031: Build Security - Comprehensive .dockerignore

## Installed Tools

Same as other devcontainers:
- bash, git, make, sed, gawk, grep
- shellcheck, jq, file
- exiftool, poppler-utils (pdfinfo), pandoc
- curl, sudo

## Platform Notes

- **Base**: Alpine Linux 3.19 (minimal musl libc distribution)
- **Package Manager**: apk
- **Shell**: Bash (installed, not default ash)
- **Image Size**: ~100MB (vs ~450MB Ubuntu)
- **Philosophy**: Security, simplicity, resource efficiency

## Alpine-Specific Commands

```bash
# Update system
sudo apk update && sudo apk upgrade

# Install package
sudo apk add <package-name>

# Search for package
apk search <keyword>

# Package info
apk info <package-name>
```

## Differences from Ubuntu/Debian

- Uses **musl libc** instead of glibc (mostly compatible)
- Uses **BusyBox** utilities (basic versions, then GNU coreutils installed)
- Some package names differ (e.g., `exiftool` not `libimage-exiftool-perl`)
- Smaller binaries, faster container startup

See [Ubuntu README](../ubuntu/README.md) for general usage.
