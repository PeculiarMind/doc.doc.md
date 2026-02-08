# Arch Linux Development Container

Rolling release Arch Linux environment with bleeding-edge packages and all security controls.

## Quick Start

```bash
# Open in VS Code
# F1 > "Dev Containers: Reopen in Container" > Select "Arch Linux"
```

## Security Implementation

- ✅ req_0027: Secrets Management - SSH keys mounted read-only, no embedded credentials
- ✅ req_0028: Base Image Verification - SHA256 pinned Arch official image
- ✅ req_0029: Package Integrity - Official Arch repos with GPG verification (pacman)
- ✅ req_0030: Privilege Restriction - Non-root user (UID 1000), capabilities dropped
- ✅ req_0031: Build Security - Comprehensive .dockerignore

## Installed Tools

Same as other devcontainers:
- bash, git, make, sed, gawk, grep
- shellcheck, jq, file
- perl-image-exiftool, poppler (pdfinfo), pandoc
- curl, sudo

## Platform Notes

- **Release Model**: Rolling release (always latest)
- **Package Manager**: pacman
- **Shell**: Bash (latest)
- **Philosophy**: Bleeding-edge, KISS (Keep It Simple, Stupid)

## Arch-Specific Commands

```bash
# Update system
sudo pacman -Syu

# Install package
sudo pacman -S <package-name>

# Search for package
pacman -Ss <keyword>

# Package info
pacman -Si <package-name>
```

See [Ubuntu README](../ubuntu/README.md) for general usage (most applies to Arch).
