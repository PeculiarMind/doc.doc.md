# Requirement: Development Container Package Integrity

**ID**: req_0029

## Status
State: Accepted  
Created: 2026-02-08  
Last Updated: 2026-02-08

## Overview
Tools and packages installed in development containers shall be installed from trusted sources using secure protocols (HTTPS) with signature verification where supported. Package versions shall be pinned for reproducibility and security.

## Description
To prevent supply chain attacks through compromised packages, development containers must install tools and packages only from trusted repositories using secure protocols. Package manager repositories must use HTTPS to prevent man-in-the-middle attacks, and package signatures must be verified where supported by the package manager.

Package versions should be pinned (where feasible) to ensure:
- Reproducible builds across different developers and time periods
- Controlled updates with testing before adoption
- Known good versions documented for security auditing
- Prevention of automatic updates that could introduce vulnerabilities

A Bill of Materials (BOM) listing all installed tools and versions must be maintained for security auditing and vulnerability tracking.

## Motivation
**Security Risk Assessment (STRIDE/DREAD)**:
- **Threat**: Tampering - Malicious package modifies development tools or injects malware
- **Secondary Threat**: Information Disclosure - Compromised tool steals SSH keys, credentials
- **Risk Score**: 194 (HIGH)
  - DREAD Likelihood: 7.2/10
  - Damage: 9/10 (complete compromise of developer environment)
  - CIA Classification: Confidential

From security review: "Tools installed from package repositories could be compromised packages. Automatic installation during container build makes attacks consistent and difficult to detect. Package repository compromise is rare but catastrophic in impact."

## Category
- Type: Security (Development Environment - Supply Chain)
- Priority: High

## Acceptance Criteria

### Secure Protocol Requirements
- [ ] All package installations use HTTPS repositories (no HTTP)
- [ ] Package manager configurations explicitly specify HTTPS sources
- [ ] No package installations from insecure protocols (HTTP, FTP, unencrypted)
- [ ] wget/curl commands for manual tool installation use HTTPS
- [ ] Documentation explains requirement for secure protocols

### Signature Verification Requirements
- [ ] Package manager GPG signature verification enabled (apt default, verify not disabled)
- [ ] For Debian/Ubuntu: `apt-get install` verifies signatures by default
- [ ] For Arch: `pacman` verifies signatures (check `/etc/pacman.conf` SigLevel)
- [ ] Manual tool installations verify signatures or checksums where available
- [ ] Process for handling signature verification failures documented

### Version Pinning Requirements
- [ ] Critical security tools have pinned versions (shellcheck, security scanners)
- [ ] Core development tools versioned where stability important
- [ ] Pinning format documented (Debian: `package=version`, Arch: `package-version`)
- [ ] Trade-off documented: security updates vs. version stability
- [ ] Update process for pinned packages documented

### Bill of Materials (BOM)
- [ ] BOM document lists all installed packages and versions
- [ ] BOM includes tool source (repository URL or package manager)
- [ ] BOM maintained in devcontainer documentation or separate file
- [ ] BOM updated when container configuration changes
- [ ] BOM includes rationale for critical tool selections

### Tool Source Documentation
- [ ] Package repositories documented (e.g., Ubuntu official archives)
- [ ] Manual tool installation sources documented with rationale
- [ ] Trust assessment for non-standard tool sources
- [ ] Alternative sources documented if primary unavailable

### Reproducibility
- [ ] Container builds produce consistent tool sets across builds
- [ ] Developers on same devcontainer get same tool versions
- [ ] Build date entropy minimized (no "latest" without constraints)
- [ ] Lock files or version constraints prevent surprise updates

## Related Requirements
- req_0026 (Development Containers for Supported Platforms) - parent requirement
- req_0028 (Development Container Base Image Verification) - complementary base image security
- req_0031 (Development Container Build Security) - complementary build-time security

## Related Security Scope
- `01_vision/04_security/02_scopes/01_development_container_security.md` - Supply chain security interfaces

## Transition History
- [2026-02-08] Moved from Funnel to Accepted  
-- Comment: High priority security requirement approved for implementation
- [2026-02-08] Created and placed in Funnel by Security Review Agent  
-- Comment: High priority security requirement identified during feature_0005 security review (Risk Score: 194)

## Notes
Package supply chain security balances security with usability:

**Strict Version Pinning**:
- ✅ Reproducible builds
- ✅ Controlled updates with testing
- ✅ Known vulnerability landscape
- ❌ Manual update burden
- ❌ May miss security patches

**Flexible Versioning**:
- ✅ Automatic security updates
- ✅ Less maintenance burden
- ❌ Builds may vary over time
- ❌ Unexpected breaking changes

**Recommended Approach**: Pin critical security tools, allow updates for stable tools with major version constraints.

**Example Dockerfile with Package Security**:
```dockerfile
# Debian/Ubuntu package installation with version pinning
RUN apt-get update && apt-get install -y \
    # Critical tools: pin exact versions
    shellcheck=0.8.0-2 \
    git=1:2.34.1-1ubuntu1.9 \
    # Standard tools: major version constraint acceptable
    jq \
    curl \
    file \
    # Clean apt cache to reduce image size
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Manual tool installation with verification
RUN curl -fsSL https://github.com/exiftool/exiftool/releases/download/12.50/exiftool-12.50.tar.gz \
    -o exiftool.tar.gz \
    && echo "abc123def456... exiftool.tar.gz" | sha256sum -c - \
    && tar xzf exiftool.tar.gz \
    && cd Image-ExifTool-12.50 \
    && perl Makefile.PL && make install \
    && cd .. && rm -rf Image-ExifTool-12.50 exiftool.tar.gz
```

**Critical Tools for This Project** (suggested pinning):
- `shellcheck` - bash linter (security critical)
- `git` - version control (workflow critical)
- `jq` - JSON processing (functional critical)

**Standard Tools** (flexible versioning acceptable):
- `bash` - usually pinned by base image
- `coreutils` (file, stat, md5sum, etc.) - stable interfaces
- `grep`, `sed`, `awk` - POSIX standard tools

**Package Manager Signature Verification**:

**Debian/Ubuntu (apt)**:
```bash
# Verify signature checking is enabled (default)
apt-config dump | grep APT::Get::AllowUnauthenticated
# Should return false or not exist (false is default)

# Signatures verified automatically during install
apt-get update  # Updates and verifies repository signatures
apt-get install <package>  # Verifies package signatures
```

**Arch Linux (pacman)**:
```bash
# Check signature level in /etc/pacman.conf
grep SigLevel /etc/pacman.conf
# Should show: SigLevel = Required DatabaseOptional
# Or: SigLevel = PackageRequired DatabaseOptional

# Signatures verified automatically during install
pacman -Sy  # Syncs and verifies signature
pacman -S <package>  # Verifies package signature
```

**Bill of Materials Template**:
```markdown
# Development Container BOM - Ubuntu 22.04

## System Packages (apt)
| Package | Version | Source | Purpose |
|---------|---------|--------|---------|
| bash | 5.1.16-1ubuntu1 | Ubuntu Official | Shell interpreter |
| git | 1:2.34.1-1ubuntu1.9 | Ubuntu Official | Version control |
| shellcheck | 0.8.0-2 | Ubuntu Universe | Bash linter |
| jq | 1.6-2.1ubuntu3 | Ubuntu Main | JSON processor |
| file | 1:5.41-3 | Ubuntu Main | File type detection |
| coreutils | 8.32-4.1ubuntu1 | Ubuntu Main | Core utilities |

## Manual Installations
| Tool | Version | Source | Verification |
|------|---------|--------|--------------|
| exiftool | 12.50 | GitHub Release | SHA256: abc123... |

## Last Updated
2026-02-08

## Update Schedule
- Security patches: Monthly review
- Tool updates: Quarterly review
```

**Common Package Manager Security Settings**:

**.dockerignore should NOT have**:
```
# Don't ignore these - they're needed for package verification
# /etc/apt/trusted.gpg.d/
# /etc/apt/sources.list
# /usr/share/keyrings/
```

**Vulnerability Monitoring**:
- Subscribe to Ubuntu Security Notices (USN)
- Monitor Debian Security Advisories (DSA)
- Use `apt-get upgrade` for security patches
- Review CVE databases for critical tools
