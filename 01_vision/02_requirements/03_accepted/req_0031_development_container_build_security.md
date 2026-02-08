# Requirement: Development Container Build Security

**ID**: req_0031

## Status
State: Accepted  
Created: 2026-02-08  
Last Updated: 2026-02-08

## Overview
Development container Dockerfiles shall follow secure build practices including use of `.dockerignore`, layer optimization, and security linting. Build-time secrets shall never be included in image layers.

## Description
Container build process security prevents accidental exposure of sensitive data, reduces attack surface, and ensures image integrity. Secure build practices include:

- **`.dockerignore`**: Prevents sensitive files from being included in build context
- **Layer hygiene**: Minimizes layers, avoids secrets in layer history
- **Multi-stage builds**: Separates build-time dependencies from runtime image
- **Security linting**: Automated or manual checks for Dockerfile security issues
- **Build-time secrets handling**: Uses BuildKit secrets or other secure mechanisms

Dockerfiles must be treated as code and subject to security review. Even if secrets are deleted in later layers, they remain accessible in image history and must never be introduced.

## Motivation
**Security Risk Assessment (STRIDE/DREAD)**:
- **Threat**: Information Disclosure - Build-time secrets in layers accessible permanently
- **Secondary Threat**: Tampering - Insecure build practices allow modification of tools
- **Risk Score**: 202 (HIGH)
  - DREAD Likelihood: 8.4/10
  - Damage: 8/10 (secrets in image layers accessible permanently)
  - CIA Classification: Confidential

From security review: "Dockerfiles may expose secrets during build or create insecure layer structures. Build-time secrets remain in layer history even if deleted later. Insecure build practices allow attackers to inspect image history and extract sensitive data."

## Category
- Type: Security (Development Environment - Build Process)
- Priority: Medium

## Acceptance Criteria

### .dockerignore Requirements
- [ ] `.dockerignore` file present in same directory as Dockerfile
- [ ] Excludes version control: `.git/`, `.gitignore`, `.github/`
- [ ] Excludes credentials: `.ssh/`, `.gnupg/`, `.aws/`, `.azure/`
- [ ] Excludes secret files: `*.key`, `*.pem`, `*.crt`, `*.p12`, `*.pfx`
- [ ] Excludes secret directories: `secrets/`, `.env`, `.env.local`
- [ ] Excludes IDE files: `.vscode/`, `.idea/`, `*.swp`
- [ ] Excludes build artifacts not needed: `node_modules/`, `__pycache__/`, `.cache/`
- [ ] Documentation explains `.dockerignore` purpose and contents

### Build-Time Secrets Prohibition
- [ ] NO secrets in `ENV` directives (e.g., `ENV API_KEY=...`)
- [ ] NO secrets in `ARG` directives (visible in image history)
- [ ] NO secrets in `RUN` commands (remain in layer even if deleted)
- [ ] NO secrets passed via `--build-arg` (visible in `docker history`)
- [ ] If build secrets needed, use BuildKit `--secret` or other secure mechanism
- [ ] Documentation clearly states build-time secret prohibition

### Layer Optimization
- [ ] Minimize layer count by combining related `RUN` commands
- [ ] Use multi-stage builds to separate build/runtime when applicable
- [ ] Layer optimization documented with rationale
- [ ] No unnecessary files in final image layers
- [ ] Package manager caches cleaned in same layer as installation

### Command Security
- [ ] Prefer `COPY` over `ADD` (ADD has implicit tar extraction and URL support)
- [ ] If `ADD` used with URLs, document security justification
- [ ] Use absolute paths or explicit relative paths, not ambiguous paths
- [ ] Set explicit user for `USER` directive (UID or username)
- [ ] `WORKDIR` uses absolute paths

### Multi-Stage Build (If Applicable)
- [ ] Build-time dependencies separated from runtime dependencies
- [ ] Only necessary artifacts copied from build stage to runtime stage
- [ ] Build stage size not included in final image
- [ ] Multi-stage build documented with purpose

### Security Linting
- [ ] Dockerfiles linted with hadolint or manual security checklist
- [ ] Common vulnerabilities checked (root user, latest tags, secrets)
- [ ] Linting results documented or issues addressed
- [ ] Linting process repeatable (automated or documented manual steps)

### Image History Security
- [ ] Image history reviewed for accidental secret exposure
- [ ] `docker history <image>` command used to inspect layers
- [ ] Layer commands reviewed for sensitive information
- [ ] Documentation includes image history review procedure

## Related Requirements
- req_0026 (Development Containers for Supported Platforms) - parent requirement
- req_0027 (Development Container Secrets Management) - complementary secrets security
- req_0028 (Development Container Base Image Verification) - complementary image security
- req_0029 (Development Container Package Integrity) - complementary package security
- req_0030 (Development Container Privilege Restriction) - complementary runtime security

## Related Security Scope
- `01_vision/04_security/02_scopes/01_development_container_security.md` - Build process security

## Transition History
- [2026-02-08] Moved from Funnel to Accepted  
-- Comment: Medium priority security requirement approved for implementation
- [2026-02-08] Created and placed in Funnel by Security Review Agent  
-- Comment: Medium priority security requirement identified during feature_0005 security review (Risk Score: 202)

## Notes
Build-time security prevents secrets from entering image layers where they persist forever. Docker images are composed of layers, each layer recording the filesystem changes from a command.

**Critical Understanding - Layer Persistence**:
```dockerfile
# ❌ BAD - Secret remains in layer history
RUN echo "API_KEY=secret123" > /tmp/secret
RUN cat /tmp/secret  # Uses secret
RUN rm /tmp/secret   # Secret STILL in layer 1!

# ✅ GOOD - Secret never in image
RUN --mount=type=secret,id=api_key \
    API_KEY=$(cat /run/secrets/api_key) && \
    # Use API_KEY here
```

**Example .dockerignore**:
```
# Version control
.git
.gitignore
.github

# Secrets
.ssh
.gnupg
.aws
.azure
*.key
*.pem
*.crt
*.p12
*.pfx
**/secrets
**/.env
**/.env.local

# IDEs
.vscode
.idea
*.swp
*.swo

# Build artifacts
node_modules
__pycache__
*.pyc
.cache
build
dist

# Documentation (not needed in image)
docs/
*.md
LICENSE
```

**Example Secure Dockerfile**:
```dockerfile
# Multi-stage build example
FROM ubuntu:22.04@sha256:... AS builder

# Install build-time dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Build application (if applicable)
COPY src/ /build/src/
RUN cd /build && make

# Runtime stage
FROM ubuntu:22.04@sha256:...

# Create non-root user
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

# Install runtime dependencies only
# Combine RUN commands to minimize layers
RUN apt-get update && apt-get install -y \
    bash \
    git \
    jq \
    shellcheck \
    # Clean cache in same layer
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy only necessary artifacts from builder
COPY --from=builder /build/bin/app /usr/local/bin/

# Switch to non-root user
USER $USERNAME

WORKDIR /workspace

# Use CMD not ENTRYPOINT for flexibility
CMD ["/bin/bash"]
```

**Layer Optimization Examples**:
```dockerfile
# ❌ BAD - Creates 3 layers
RUN apt-get update
RUN apt-get install -y bash
RUN apt-get install -y git

# ✅ GOOD - Creates 1 layer
RUN apt-get update && apt-get install -y \
    bash \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ❌ BAD - Cache remains in layer
RUN apt-get update && apt-get install -y bash
RUN rm -rf /var/lib/apt/lists/*  # Too late, in different layer!

# ✅ GOOD - Cache cleaned in same layer
RUN apt-get update && apt-get install -y bash \
    && rm -rf /var/lib/apt/lists/*
```

**COPY vs ADD Security**:
```dockerfile
# ✅ PREFERRED - Explicit, predictable
COPY src/ /app/src/

# ⚠️ USE WITH CAUTION - Implicit tar extraction, URL support
ADD archive.tar.gz /app/  # Automatically extracts
ADD https://example.com/file /tmp/  # Downloads, but no checksum verification

# ✅ IF NEEDED - Explicit and verifiable
RUN curl -fsSL https://example.com/file -o /tmp/file \
    && echo "abc123... /tmp/file" | sha256sum -c -
```

**BuildKit Secrets** (Secure build-time secrets if needed):
```dockerfile
# Enable BuildKit syntax
# syntax=docker/dockerfile:1.4

FROM ubuntu:22.04@sha256:...

# Use secret without leaving trace in layer
RUN --mount=type=secret,id=github_token \
    GITHUB_TOKEN=$(cat /run/secrets/github_token) && \
    curl -H "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/user/repos

# Build command:
# DOCKER_BUILDKIT=1 docker build --secret id=github_token,src=token.txt .
```

**Security Linting with hadolint**:
```bash
# Install hadolint
docker run --rm -i hadolint/hadolint < Dockerfile

# Common checks:
# - DL3000: No absolute paths in WORKDIR
# - DL3002: USER should be non-root
# - DL3008: Pin versions in apt-get install
# - DL3009: Delete apt cache in same layer
# - DL3015: Avoid additional packages for apt
# - DL4006: Use SHELL for pipefail
```

**Image History Inspection**:
```bash
# View all layers and commands
docker history <image>

# View detailed layer info including sizes
docker history --no-trunc <image>

# Check for secrets in layers (manual review needed)
docker history <image> | grep -i "secret\|token\|key\|password"
```

**Security Review Checklist for Dockerfiles**:
- [ ] No secrets in any directive (ENV, ARG, RUN, COPY)
- [ ] `.dockerignore` present and comprehensive
- [ ] Non-root USER specified
- [ ] Base image pinned with digest
- [ ] HTTPS used for all external resources
- [ ] Package manager caches cleaned in same layer
- [ ] Minimal layers (combined RUN commands)
- [ ] COPY preferred over ADD
- [ ] Absolute paths in WORKDIR
- [ ] No unnecessary tools in final image
- [ ] Multi-stage build used if applicable
- [ ] Image history reviewed for leaks

**Common Mistakes to Avoid**:
1. **Deleting secrets in later command**: Secret remains in layer history
2. **Using `ARG` for secrets**: Visible in `docker history`
3. **Exposing credentials in URL**: `ADD https://user:pass@example.com/file`
4. **Not cleaning package caches**: Bloats image, wastes space
5. **Using `:latest` tag**: Unpredictable, not immutable
6. **Running as root**: Unnecessary privilege
7. **Copying entire context**: Use `.dockerignore` to limit

**Best Practices Summary**:
✅ Use `.dockerignore` comprehensively
✅ Never put secrets in layers (use BuildKit secrets if needed)
✅ Combine related RUN commands
✅ Clean caches in same layer
✅ Run as non-root user
✅ Use multi-stage builds for complex builds
✅ Lint Dockerfiles for security issues
✅ Review image history before sharing
