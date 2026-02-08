# Ubuntu 22.04 Development Container

## Overview

This devcontainer provides a Ubuntu 22.04 LTS environment for developing and testing doc.doc.md. It includes all necessary tools pre-configured with comprehensive security controls.

## Quick Start

1. **Install Prerequisites**:
   - [VS Code](https://code.visualstudio.com/)
   - [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
   - [Docker Desktop](https://www.docker.com/products/docker-desktop) or compatible container runtime

2. **Open in Container**:
   ```bash
   # Option 1: VS Code Command Palette
   code .
   # Then: F1 > "Dev Containers: Reopen in Container" > Select "Ubuntu 22.04"
   
   # Option 2: Direct command
   code --folder-uri=vscode-remote://dev-container+${PWD}/.devcontainer/ubuntu
   ```

3. **Start Development**:
   ```bash
   # Run tests
   ./tests/run_all_tests.sh
   
   # Check tool availability
   bash --version
   shellcheck --version
   exiftool -ver
   ```

## Installed Tools

### Core Development
- **bash** 5.1+ - Shell interpreter
- **git** - Version control
- **make**, **sed**, **gawk**, **grep** - Build and text processing

### Testing & Quality
- **shellcheck** - Bash linting
- **jq** - JSON processing
- **file** - File type detection

### Metadata Extraction
- **exiftool** - EXIF/metadata extraction
- **pdfinfo** (poppler-utils) - PDF metadata
- **md5sum**, **sha256sum** - Checksums

### Documentation
- **pandoc** - Document conversion

## Security Implementation

This devcontainer implements **5 critical security requirements**:

### ✅ req_0027: Secrets Management (CRITICAL)
- **No secrets in Dockerfile or image layers**
- SSH keys mounted read-only from host `~/.ssh/`
- Git credentials via SSH agent forwarding
- `.dockerignore` excludes all credential files from build context

### ✅ req_0028: Base Image Verification (HIGH)
- Base image pinned with SHA256 digest
- Uses Docker Official Image: `ubuntu:22.04@sha256:0e5e4a57...`
- Prevents supply chain attacks via image tampering

### ✅ req_0029: Package Integrity (HIGH)
- All packages from official Ubuntu repositories
- HTTPS transport with GPG signature verification (apt default)
- No third-party PPAs or untrusted sources

### ✅ req_0030: Privilege Restriction (HIGH)
- Runs as non-root user `devuser` (UID 1000)
- All capabilities dropped (`--cap-drop=ALL`)
- `no-new-privileges` security option enabled
- Mounts limited to project workspace and read-only credentials

### ✅ req_0031: Build Security (MEDIUM)
- Comprehensive `.dockerignore` prevents credential leakage
- No secrets in `ENV`, `ARG`, `COPY`, or `RUN` commands
- Minimal attack surface (only essential packages)

## File Structure

```
.devcontainer/ubuntu/
├── devcontainer.json    # VS Code Dev Container configuration
├── Dockerfile           # Container image definition
├── .dockerignore        # Build context exclusions (security)
├── README.md            # This file
└── BOM.md              # Bill of Materials (package list)
```

## Usage Tips

### SSH Agent Forwarding
Your host SSH agent is forwarded to the container automatically:
```bash
# Test SSH agent
ssh-add -l

# Clone private repos
git clone git@github.com:user/private-repo.git
```

### Git Configuration
Your host `.gitconfig` is mounted read-only:
```bash
# Verify git identity
git config --list | grep user

# Sign commits (GPG agent forwarding required separately)
git commit -S -m "Signed commit"
```

### Installing Additional Packages
```bash
# Use sudo (passwordless for devuser)
sudo apt-get update
sudo apt-get install <package-name>
```

### Rebuilding Container
If you modify the Dockerfile:
```bash
# In VS Code: F1 > "Dev Containers: Rebuild Container"
# Or: F1 > "Dev Containers: Rebuild Container Without Cache"
```

## Troubleshooting

### SSH Keys Not Working
- Ensure SSH agent is running on host: `eval $(ssh-agent)`
- Add keys to agent: `ssh-add ~/.ssh/id_ed25519`
- Verify mount: `ls -la ~/.ssh/` (should see keys)

### Permission Denied on Files
- Container user UID (1000) should match host user UID
- Check with: `id` (in container) vs `id` (on host)
- Solution: Adjust `USER_UID` in Dockerfile if needed

### Git Push Asks for Password
- Ensure SSH URLs, not HTTPS: `git remote -v`
- Change to SSH: `git remote set-url origin git@github.com:user/repo.git`
- Verify SSH agent: `ssh-add -l`

### Tools Not Found
- Rebuild container to get latest packages
- Check tool installation in Dockerfile
- Install manually: `sudo apt-get install <tool>`

## Platform Notes

### Ubuntu Specifics
- **LTS Version**: 22.04 (Jammy Jellyfish) - supported until April 2027
- **Package Manager**: apt/dpkg
- **Shell**: Bash 5.1.16
- **Init System**: systemd (not running in container)

### Differences from Other Platforms
- Uses `apt-get` instead of `pacman` (Arch) or `apk` (Alpine)
- Package names may differ (e.g., `poppler-utils` vs `poppler`)
- GNU coreutils instead of busybox (fuller feature set)

## Performance

- **Image Size**: ~450MB (base + packages)
- **Build Time**: ~2-3 minutes (first build, then cached)
- **Startup Time**: ~5-10 seconds (after initial build)

## Security Verification

Verify security controls are active:
```bash
# Check user
whoami  # Should output: devuser

# Check capabilities (should be minimal)
sudo apt-get install -y libcap2-bin
capsh --print

# Check mounts (should be limited)
mount | grep /workspace
mount | grep /home/devuser

# Verify no secrets in image
docker history <image-id>  # Review layers for sensitive data
```

## Support

For issues specific to this devcontainer:
1. Check [main README.md](../../README.md) for general setup
2. Review [CONTRIBUTING.md](../../CONTRIBUTING.md) for development guidelines
3. Open issue on GitHub with devcontainer logs

## License

Same as parent project - see [LICENSE](../../LICENSE)
