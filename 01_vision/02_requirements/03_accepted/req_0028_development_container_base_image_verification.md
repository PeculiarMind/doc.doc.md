# Requirement: Development Container Base Image Verification

**ID**: req_0028

## Status
State: Accepted  
Created: 2026-02-08  
Last Updated: 2026-02-08

## Overview
Development container base images shall be from trusted sources with version pinning and digest verification. Base images shall be regularly updated for security patches and scanned for known vulnerabilities.

## Description
To prevent supply chain attacks through compromised base container images, development containers must use base images from verified trusted sources (Docker Official Images, verified publishers, or organizational registries). Base image references must include both version tags AND SHA256 digest pins to ensure image integrity and prevent tag hijacking attacks.

Base images shall be selected from:
- Docker Official Images (highest trust)
- Verified Publishers on Docker Hub
- Organizational/enterprise trusted registries
- Well-maintained distributions (Ubuntu, Debian, Arch official images)

Image references must use the format: `<image>:<tag>@sha256:<digest>` to ensure immutability.

Regular vulnerability scanning and update schedules must be established to address security patches in base images.

## Motivation
**Security Risk Assessment (STRIDE/DREAD)**:
- **Threat**: Tampering - Malicious base image injects backdoors or modifies tools
- **Secondary Threat**: Information Disclosure - Compromised image exfiltrates developer credentials
- **Risk Score**: 173 (HIGH)
  - DREAD Likelihood: 7.2/10
  - Damage: 8/10 (compromised dev environment can access host filesystem, credentials)
  - CIA Classification: Confidential

From security review: "Base images may contain vulnerabilities or be compromised at the source. Image tag hijacking (where malicious image replaces legitimate tag) is possible without digest pinning. Developers trust base images implicitly, making this an effective attack vector."

## Category
- Type: Security (Development Environment - Supply Chain)
- Priority: High

## Acceptance Criteria

### Base Image Source Requirements
- [ ] Base images sourced from Docker Official Images (preferred) OR
- [ ] Base images from Verified Publishers with documented trust assessment OR
- [ ] Base images from organizational trusted registry with security controls
- [ ] NO base images from unverified personal repositories
- [ ] Dockerfile comments document base image selection rationale

### Image Pinning Requirements
- [ ] Base image references include version tag (e.g., `ubuntu:22.04`)
- [ ] Base image references include SHA256 digest pin (e.g., `@sha256:abc123...`)
- [ ] Full format: `FROM ubuntu:22.04@sha256:<full-64-char-digest>`
- [ ] Digest verification documented in build process
- [ ] Process documented for updating digest when base image updates

### Vulnerability Management
- [ ] Vulnerability scanning process defined (automated or manual)
- [ ] Vulnerability scanning performed on base images before use
- [ ] Known HIGH/CRITICAL vulnerabilities addressed or risk-accepted with documentation
- [ ] Update schedule defined (e.g., quarterly base image review)
- [ ] Security advisory monitoring for base image distributions (Ubuntu Security Notices, etc.)

### Documentation Requirements
- [ ] Base image selection criteria documented
- [ ] Trust assessment for chosen base images documented
- [ ] SHA256 digest derivation process documented (how to get correct digest)
- [ ] Base image update procedures documented
- [ ] Vulnerability scanning results documented (or scan reports retained)

### Change Management
- [ ] Process for base image updates defined
- [ ] Testing requirements after base image changes defined
- [ ] Rollback procedure if base image update causes issues
- [ ] Communication plan for base image changes to development team

## Related Requirements
- req_0026 (Development Containers for Supported Platforms) - parent requirement
- req_0029 (Development Container Package Integrity) - complementary package security
- req_0031 (Development Container Build Security) - complementary build-time security

## Related Security Scope
- `01_vision/04_security/02_scopes/01_development_container_security.md` - Supply chain security interfaces

## Transition History
- [2026-02-08] Moved from Funnel to Accepted  
-- Comment: High priority security requirement approved for implementation
- [2026-02-08] Created and placed in Funnel by Security Review Agent  
-- Comment: High priority security requirement identified during feature_0005 security review (Risk Score: 173)

## Notes
Base image security is foundational to container security. A compromised base image undermines all other security controls because:
- Malicious base could modify any tools or inject backdoors
- Container starts from base image, inheriting all vulnerabilities
- Developers typically trust base images without verification

**Version Pinning vs Digest Pinning**:
- **Version tag** (e.g., `ubuntu:22.04`): Mutable, can be hijacked or updated
- **Digest pin** (e.g., `@sha256:abc...`): Immutable, cryptographically verifies exact image
- **Both required**: Tag for readability, digest for security

**How to Get SHA256 Digest**:
1. Pull image: `docker pull ubuntu:22.04`
2. Inspect: `docker inspect ubuntu:22.04 | grep -i sha256`
3. Or use: `docker images --digests ubuntu:22.04`
4. Full reference: `ubuntu:22.04@sha256:<digest-from-step-2>`

**Example Dockerfile**:
```dockerfile
# Good: Trusted source + version + digest
FROM ubuntu:22.04@sha256:6d7b5d3317a71adb5e3a0213ecc6e618e2e5e5a6d4e1a8b8e5f5e1e5e5e5e5e5

# BAD: No digest (mutable)
FROM ubuntu:22.04

# BAD: No version (unpredictable)
FROM ubuntu:latest

# BAD: Untrusted source
FROM randomuser/ubuntu-custom:latest
```

**Vulnerability Scanning Tools** (for reference):
- Trivy (open source, comprehensive)
- Docker Scan (built into Docker CLI)
- Snyk Container (commercial)
- Clair (open source)
- Anchore (enterprise)

**Recommended Update Schedule**:
- **Critical vulnerabilities**: Immediate update
- **High vulnerabilities**: Within 30 days
- **Medium/Low vulnerabilities**: Quarterly review
- **General updates**: LTS release updates (Ubuntu: every 2 years for .04 releases)

**Acceptable Base Images for This Project**:
- `ubuntu:22.04@sha256:...` - Docker Official Image, LTS until 2027
- `debian:12@sha256:...` - Docker Official Image, stable release
- `archlinux:latest@sha256:...` - Docker Official Image (rolling, requires more frequent updates)
- Generic alpine/busybox may be too minimal for bash development tooling
