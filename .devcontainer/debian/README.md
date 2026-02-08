# Debian 12 Development Container

Debian 12 (Bookworm) stable development environment with all security controls implemented.

## Quick Start

```bash
# Open in VS Code
# F1 > "Dev Containers: Reopen in Container" > Select "Debian 12"
```

## Security Implementation

- ✅ req_0027: Secrets Management - SSH keys mounted read-only, no embedded credentials
- ✅ req_0028: Base Image Verification - SHA256 pinned Debian 12 official image
- ✅ req_0029: Package Integrity - Official Debian repos with GPG verification
- ✅ req_0030: Privilege Restriction - Non-root user (UID 1000), capabilities dropped
- ✅ req_0031: Build Security - Comprehensive .dockerignore

## Installed Tools

Same as Ubuntu devcontainer:
- bash, git, make, sed, gawk, grep
- shellcheck, jq, file
- exiftool, pdfinfo, pandoc
- curl, sudo

## Platform Notes

- **Stable Release**: Debian 12 (Bookworm)
- **Package Manager**: apt/dpkg
- **Shell**: Bash 5.2
- **Support**: Until ~2028 (Debian LTS)

See [Ubuntu README](../ubuntu/README.md) for detailed usage instructions (most apply to Debian).
