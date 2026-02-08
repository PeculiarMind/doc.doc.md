# Security Scope: Development Container Security

**Scope ID**: scope_dev_container_001  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08  
**Status**: Active

## Overview
This security scope defines the security boundaries, components, interfaces, threats, and controls for development container environments used by contributors to this project. Development containers provide consistent, reproducible development environments via VS Code Dev Containers, Docker, and platform-specific container images.

## Scope Definition

### In Scope
- Dockerfile security and build practices
- devcontainer.json configuration security
- Container runtime security (user privileges, capabilities, isolation)
- Host-to-container interface security (mounts, networking, secrets)
- Base image and package supply chain security
- Development credential management (SSH keys, Git credentials, GPG keys)
- Build-time secret handling
- Container image integrity and distribution

### Out of Scope
- Production container deployments (this project doesn't deploy containers in production)
- Kubernetes or orchestration security (not used for development)
- Container registry security (images built locally, not pushed to registry)
- Host operating system security (assumed trusted developer machine)
- VS Code editor security (assumed trusted installation)
- Docker daemon security configuration (relies on developer's Docker installation)

## Components

### 1. Dockerfile
**Purpose**: Defines container image build instructions including base image, package installations, user configuration, and filesystem setup.

**Security Properties**:
- Must not contain secrets (credentials, keys, tokens)
- Must use trusted base images with digest pinning
- Must create non-root user for container execution
- Must minimize attack surface (minimal packages, cleaned caches)

**CIA Classification**: Internal (Dockerfile itself), but must protect Highly Confidential data from leaking into it

### 2. devcontainer.json
**Purpose**: VS Code Dev Containers configuration defining mounts, environment variables, extensions, and runtime parameters.

**Security Properties**:
- Defines host-to-container mounts (must be minimal and appropriate)
- Specifies container user (must be non-root)
- Configures security options (capabilities, privileges)
- Sets environment variables (must not contain secrets)

**CIA Classification**: Internal (configuration), Highly Confidential (if misconfigured to expose secrets)

### 3. .dockerignore
**Purpose**: Excludes files from Docker build context to prevent accidental inclusion of sensitive files.

**Security Properties**:
- Must exclude credential directories (.ssh, .gnupg, .aws)
- Must exclude secret files (*.key, *.pem, secrets/)
- Must exclude environment files (.env, .env.local)
- Acts as defense-in-depth against secret leakage

**CIA Classification**: Internal

### 4. Container Image Layers
**Purpose**: Immutable filesystem layers created during image build, forming final container image.

**Security Properties**:
- Layers are immutable and permanently retain content
- Secrets in any layer remain accessible via docker history
- Layer count affects attack surface and build performance
- Base layers come from external sources (supply chain risk)

**CIA Classification**: Confidential (could contain exposed secrets if misconfigured)

### 5. Container Runtime
**Purpose**: Running container process managed by Docker daemon providing isolated execution environment.

**Security Properties**:
- Runs as non-root user (privilege restriction)
- Has dropped Linux capabilities (attack surface reduction)
- Uses no-new-privileges flag (privilege escalation prevention)
- Isolated from host via Linux namespaces and cgroups

**CIA Classification**: Confidential (accesses developer source code and credentials)

### 6. Base Container Images
**Purpose**: Foundation images (Ubuntu, Debian, Arch) providing operating system and base tools.

**Security Properties**:
- Source from trusted registries (Docker Official Images)
- Must be pinned with SHA256 digest (integrity verification)
- May contain vulnerabilities requiring updates
- Supply chain risk: compromise spreads to all dependent images

**CIA Classification**: Internal (image itself), but critical trust anchor

### 7. Installed Packages
**Purpose**: CLI tools and development dependencies installed via package managers (apt, pacman).

**Security Properties**:
- Installed from distribution repositories (supply chain)
- Signature verification via package manager (when available)
- Version pinning provides reproducibility and controlled updates
- Vulnerable packages expose container and potentially host

**CIA Classification**: Internal (packages), Confidential (if compromised)

## Interfaces

### Interface 1: Host Filesystem to Container (Bind Mounts)
**Description**: Host directories mounted into container for code access and credential sharing.

**Data Flow**: Bidirectional (read/write for project, read-only for credentials)

**Security Concerns**:
- Excessive mounts (entire /home) expose sensitive host files
- Write access to host directories allows host file modification
- Credential mounts must be read-only
- Docker socket mount (`/var/run/docker.sock`) grants host root access

**Threat Model (STRIDE)**:
- **Tampering**: Malicious container process modifies host files via mounted directories
- **Information Disclosure**: Container reads sensitive host files outside project scope
- **Elevation of Privilege**: Container writes to setuid binaries on host filesystem
- **Denial of Service**: Container fills host filesystem via mounted directory

**Controls**:
- Mount only project directory for read-write access
- Mount credentials read-only (.ssh, .gitconfig)
- Never mount sensitive host paths (/etc, /root, /var)
- Never mount Docker socket unless explicitly required and documented

**Related Requirements**: req_0030 (Privilege Restriction), req_0027 (Secrets Management)

### Interface 2: SSH Agent Forwarding Socket
**Description**: Unix domain socket forwarding SSH agent from host to container for git authentication.

**Data Flow**: Bidirectional (SSH protocol over socket)

**Security Concerns**:
- Compromised container could abuse SSH agent to authenticate as developer
- Agent socket access grants all SSH keys the agent holds
- Container processes can use agent without key passphrase

**Threat Model (STRIDE)**:
- **Spoofing**: Malicious container impersonates developer via SSH agent
- **Information Disclosure**: Container cannot extract private keys, but can use them
- **Repudiation**: Actions via agent forwarding appear as legitimate developer actions

**Controls**:
- Prefer agent forwarding over copying keys (keys never enter container)
- Container isolation limits agent access to container processes only
- Non-root user prevents some agent abuse scenarios
- Document that container can use SSH agent (accepted risk for convenience)

**Related Requirements**: req_0027 (Secrets Management)

### Interface 3: Git Credential Helper
**Description**: Git credential storage mechanism for HTTPS authentication (alternative to SSH).

**Data Flow**: Git queries credential helper, receives credentials

**Security Concerns**:
- Credentials stored in container filesystem exposed if container compromised
- Credential helpers may leak credentials via logs or error messages
- Shared credentials prevent attribution

**Threat Model (STRIDE)**:
- **Information Disclosure**: Stored credentials readable by container processes
- **Spoofing**: Malicious container uses credentials to impersonate developer
- **Repudiation**: Actions with shared credentials not attributable

**Controls**:
- Prefer SSH agent forwarding over HTTPS with stored credentials
- If credential helper needed, use cache mode (limited time) not store mode
- Mount credential helper config from host (don't store in container)
- Document security implications of credential helpers

**Related Requirements**: req_0027 (Secrets Management)

### Interface 4: Container Network Interface
**Description**: Network connectivity from container to external networks (package repositories, internet).

**Data Flow**: Outbound connections from container (package installs, git clone)

**Security Concerns**:
- Compromised container could exfiltrate data via network
- Container could be used as attack platform against other systems
- Network interception possible if not using HTTPS

**Threat Model (STRIDE)**:
- **Information Disclosure**: Compromised container exfiltrates source code or credentials
- **Denial of Service**: Compromised container launches attacks on other systems
- **Tampering**: Man-in-the-middle attacks on HTTP package installations

**Controls**:
- Require HTTPS for all package repositories (no HTTP)
- Consider network policies limiting outbound connections (advanced)
- No host networking mode (use bridge network isolation)
- Document network requirements and acceptable use

**Related Requirements**: req_0029 (Package Integrity)

### Interface 5: Package Manager to Distribution Repositories
**Description**: apt, pacman, or other package managers downloading and installing packages.

**Data Flow**: Outbound HTTPS to repository, package download and installation

**Security Concerns**:
- Compromised repository serves malicious packages
- Man-in-the-middle attack replaces legitimate packages
- Unsigned packages lack integrity verification
- Transitive dependencies expand attack surface

**Threat Model (STRIDE)**:
- **Tampering**: Malicious package replaces legitimate tool with backdoored version
- **Information Disclosure**: Compromised tool steals credentials or source code
- **Spoofing**: Malicious package masquerades as legitimate tool

**Controls**:
- Use HTTPS for all repository connections
- Enable package signature verification (apt/pacman default)
- Pin package versions for reproducibility
- Maintain Bill of Materials (BOM) for installed packages
- Subscribe to security advisories for distributions

**Related Requirements**: req_0029 (Package Integrity), req_0028 (Base Image Verification)

### Interface 6: Docker Build Context
**Description**: Files and directories sent from host to Docker daemon for image build.

**Data Flow**: Host → Docker daemon (one-way)

**Security Concerns**:
- Build context may accidentally include sensitive files
- Large build contexts expose more potential secrets
- Build context contents persist in Docker daemon until cleaned

**Threat Model (STRIDE)**:
- **Information Disclosure**: Secrets in build context included in image layers
- **Tampering**: Malicious files in build context affect build process

**Controls**:
- Use `.dockerignore` to exclude sensitive files and directories
- Minimize build context size (performance and security)
- Review build context contents before building
- Never include .ssh, .gnupg, .env, secrets/ in build context

**Related Requirements**: req_0031 (Build Security), req_0027 (Secrets Management)

### Interface 7: Container Image Registry (Future)
**Description**: Docker Hub or other registry for sharing pre-built images (currently out of scope: local builds only).

**Data Flow**: Bidirectional (push/pull images)

**Security Concerns** (if used in future):
- Image tampering during transit or storage
- Tag hijacking (malicious image replaces legitimate tag)
- Lack of provenance (can't verify image source)

**Threat Model (STRIDE)**:
- **Tampering**: Malicious image replaces legitimate image in registry
- **Spoofing**: Fake image masquerades as official devcontainer
- **Information Disclosure**: Secrets accidentally pushed in image layers

**Controls** (if future registry use):
- Use digest pinning for image pulls
- Implement image signing (Docker Content Trust)
- Scan images for secrets before pushing
- Use private registry for organizational images

**Related Requirements**: N/A (out of current scope)

## Data Formats

### Dockerfile Syntax
**Format**: Text file with Docker build instructions (FROM, RUN, COPY, USER, etc.)

**Security Considerations**:
- Secrets in Dockerfile persist in image layers permanently
- Build commands visible via `docker history`
- Comments visible in build process (don't put secrets in comments)

**CIA Classification**: Internal (Dockerfile content without secrets)

### devcontainer.json Schema
**Format**: JSON configuration for VS Code Dev Containers

**Security Considerations**:
- Environment variables defined here visible in container
- Mounts defined here control host filesystem access
- Security options (runArgs) control container isolation

**CIA Classification**: Internal

### Container Image Layers (tar.gz)
**Format**: Compressed filesystem changesets forming image layers

**Security Considerations**:
- Each layer immutable and inspectable via `docker history`
- Deleted files in later layers still present in earlier layers
- Secrets in any layer permanently accessible

**CIA Classification**: Confidential (may contain secrets if misconfigured)

### Package Metadata
**Format**: Debian packages (.deb), Arch packages (.pkg.tar.zst)

**Security Considerations**:
- Packages contain cryptographic signatures for verification
- Package metadata includes maintainer, version, dependencies
- Compromised packages detectable via signature verification

**CIA Classification**: Public (package metadata), Internal (installed packages)

## Protocols

### SSH Protocol (for Agent Forwarding)
**Version**: SSH-2
**Encryption**: Yes (ephemeral keys for agent forwarding)

**Security Considerations**:
- Agent forwarding creates attack surface (agent hijacking)
- Forwarded agent accessible to all container processes
- Prefer agent confirmation for sensitive keys (not default)

**Related Requirements**: req_0027 (Secrets Management)

### HTTPS (for Package Downloads)
**Version**: TLS 1.2+ (managed by package managers)
**Encryption**: Yes

**Security Considerations**:
- Prevents man-in-the-middle attacks on package downloads
- Certificate validation ensures repository authenticity
- Must not fall back to HTTP

**Related Requirements**: req_0029 (Package Integrity)

### Docker Engine API
**Version**: Docker API v1.41+
**Transport**: Unix domain socket or TCP (local only)

**Security Considerations**:
- Unix socket access grants control over Docker daemon
- Mounting Docker socket equivalent to root on host
- Dev Containers use this API to manage container lifecycle

**Related Requirements**: req_0030 (Privilege Restriction)

## CIA Classification and Risk Assessment

### Data Classification

#### Highly Confidential
- **SSH Private Keys**: Developer identity, repository access
- **GPG Private Keys**: Commit signing, package signing
- **Git Credentials**: Repository authentication (HTTPS tokens, passwords)
- **API Tokens**: Third-party service authentication

**Risk**: Complete identity theft, unauthorized repository access, forged commits
**Weight**: 4x in risk calculations

#### Confidential
- **Source Code**: Intellectual property, pre-release features
- **Developer Environment Configuration**: May reveal internal practices
- **Container Filesystem**: May contain credentials or sensitive data during development
- **Host Filesystem Paths**: May reveal organizational structure

**Risk**: Code theft, competitive disadvantage, information leakage
**Weight**: 3x in risk calculations

#### Internal
- **Dockerfile Contents**: Build instructions (without secrets)
- **devcontainer.json**: Development environment configuration
- **Package Lists**: Tools and versions installed
- **Build Logs**: Container build output (without secrets)

**Risk**: Limited, primarily informational
**Weight**: 2x in risk calculations

#### Public
- **Base Image References**: Ubuntu, Debian, Arch official images
- **Package Names**: Standard tools (bash, git, shellcheck)
- **Project Structure**: Public repository structure

**Risk**: Minimal, already public information
**Weight**: 1x in risk calculations

### Threat Model Summary (STRIDE)

| Threat Category | Key Threats | Risk Level | Related Requirements |
|----------------|-------------|------------|---------------------|
| **Spoofing** | SSH agent forwarding abuse, stolen credentials | HIGH | req_0027 |
| **Tampering** | Malicious packages, base image compromise, host file modification | HIGH | req_0028, req_0029, req_0030 |
| **Repudiation** | Shared credentials prevent attribution | MEDIUM | req_0027 |
| **Information Disclosure** | Secrets in image layers, credential exposure, source code exfiltration | CRITICAL | req_0027, req_0031 |
| **Denial of Service** | Container resource exhaustion, host filesystem filling | MEDIUM | req_0030 |
| **Elevation of Privilege** | Root container + kernel vulnerability, excessive capabilities | HIGH | req_0030 |

### Risk Scores (DREAD)

| Risk | Damage | Reproducibility | Exploitability | Affected Users | Discoverability | Likelihood | Risk Score | Priority |
|------|--------|----------------|----------------|----------------|----------------|------------|------------|----------|
| Secrets in Image Layers | 10 | 9 | 8 | 10 | 8 | 8.8 | 352 (×4) | CRITICAL |
| Privilege Escalation | 9 | 7 | 5 | 10 | 7 | 7.6 | 205 (×3) | HIGH |
| Build-Time Secret Exposure | 8 | 9 | 8 | 10 | 7 | 8.4 | 202 (×3) | HIGH |
| Package Supply Chain Attack | 9 | 8 | 4 | 10 | 5 | 7.2 | 194 (×3) | HIGH |
| Base Image Compromise | 8 | 7 | 5 | 10 | 6 | 7.2 | 173 (×3) | HIGH |
| Credential Workflow Exposure | 6 | 5 | 6 | 7 | 5 | 5.8 | 104 (×3) | MEDIUM |

## Security Controls

### Preventive Controls

#### Secrets Management (req_0027)
- **Control**: Never copy secrets into Dockerfile or container images
- **Implementation**: Use SSH agent forwarding, read-only mounts, BuildKit secrets
- **Verification**: Scan Dockerfiles and image history for secrets
- **Residual Risk**: Agent forwarding creates smaller attack surface but still accessible

#### Base Image Verification (req_0028)
- **Control**: Use trusted base images with SHA256 digest pinning
- **Implementation**: `FROM ubuntu:22.04@sha256:<digest>`
- **Verification**: Document base image source and update process
- **Residual Risk**: Trusted source compromise still possible (low probability)

#### Package Integrity (req_0029)
- **Control**: HTTPS repositories, signature verification, version pinning
- **Implementation**: Configure package managers, maintain BOM
- **Verification**: Review package sources and signatures
- **Residual Risk**: Repository compromise or sophisticated supply chain attack

#### Privilege Restriction (req_0030)
- **Control**: Non-root user, dropped capabilities, minimal mounts, no-new-privileges
- **Implementation**: USER directive, remoteUser config, runArgs capabilities
- **Verification**: Inspect container user, capabilities, and mounts
- **Residual Risk**: Kernel vulnerabilities still allow potential container escape

#### Build Security (req_0031)
- **Control**: `.dockerignore`, layer hygiene, multi-stage builds, security linting
- **Implementation**: Comprehensive `.dockerignore`, combined RUN commands, hadolint
- **Verification**: Review image history, lint Dockerfiles
- **Residual Risk**: Human error during Dockerfile creation

### Detective Controls

#### Secret Scanning
- **Tool**: git-secrets, truffleHog, gitleaks, manual inspection
- **Frequency**: Before container build, during code review
- **Action**: Revoke and rotate compromised secrets immediately

#### Vulnerability Scanning
- **Tool**: Trivy, Docker Scan, Snyk, Clair
- **Frequency**: Monthly for base images, before production use
- **Action**: Update vulnerable packages or accept risk with documentation

#### Image History Inspection
- **Command**: `docker history <image>`
- **Frequency**: After container build, before sharing
- **Action**: Rebuild image to remove exposed secrets

#### Security Audit
- **Checklist**: Dockerfile security checklist, devcontainer.json review
- **Frequency**: During feature implementation, periodic review
- **Action**: Address findings before merging

### Corrective Controls

#### Secret Rotation
- **Trigger**: Secret exposure detected in image or build process
- **Action**: Revoke compromised keys, rotate credentials, rebuild images
- **Documentation**: Incident response procedure

#### Image Rebuild
- **Trigger**: Secret found in image history, vulnerable base image
- **Action**: Fix Dockerfile, rebuild image, verify with history inspection
- **Documentation**: Build process documentation

#### Security Update Process
- **Trigger**: Critical vulnerability in base image or package
- **Action**: Update base image/package, test devcontainer, deploy update
- **Documentation**: Update schedule and procedures

## Residual Risks

### Accepted Risks

#### Container Escape via Kernel Vulnerability
- **Description**: Despite privilege restrictions, kernel vulnerabilities may allow container escape
- **Likelihood**: Low (requires kernel 0-day or unpatched vulnerability)
- **Impact**: High (host system compromise)
- **Mitigation**: Privilege restrictions reduce attack surface, keep host kernel updated
- **Acceptance Rationale**: Risk balanced by development environment convenience

#### SSH Agent Abuse
- **Description**: Compromised container can use SSH agent to authenticate as developer
- **Likelihood**: Medium (if container compromised)
- **Impact**: High (unauthorized repository access)
- **Mitigation**: Agent forwarding preferred over copying keys, container isolation limits scope
- **Acceptance Rationale**: Trade-off for developer convenience, keys never extracted

#### Developer Machine Compromise
- **Description**: Host machine compromise affects all containers and credentials
- **Likelihood**: Low (assuming trusted developer machines)
- **Impact**: Critical (complete environment compromise)
- **Mitigation**: Out of scope - relies on host security practices
- **Acceptance Rationale**: Development containers assume trusted host

#### Build Performance vs Security Trade-offs
- **Description**: Version pinning and security checks slow build process
- **Likelihood**: Certain (by design)
- **Impact**: Low (development convenience)
- **Mitigation**: Cache layers, balance pinning with flexibility
- **Acceptance Rationale**: Security prioritized over minor performance impact

## Security Testing

### Build-Time Tests
- [ ] `.dockerignore` excludes all sensitive file patterns
- [ ] Dockerfile uses non-root `USER` directive
- [ ] Base image includes SHA256 digest pinning
- [ ] No secrets in Dockerfile (ENV, ARG, RUN, COPY)
- [ ] Image history contains no secrets (automated scan)
- [ ] Dockerfile passes security linter (hadolint)

### Runtime Tests
- [ ] Container runs as non-root user (`whoami` returns non-root)
- [ ] Container has minimal capabilities (`capsh --print`)
- [ ] no-new-privileges flag set (`docker inspect`)
- [ ] Mounts limited to project directory (no sensitive host paths)
- [ ] No Docker socket mounted (unless explicitly required)
- [ ] SSH agent forwarding works correctly
- [ ] Git authentication works (SSH or credential helper)

### Integration Tests
- [ ] Full build and test workflow succeeds in devcontainer
- [ ] Cross-platform testing (Ubuntu, Debian, Arch) successful
- [ ] Developer can switch between devcontainers correctly
- [ ] Tool availability verification passes all required tools
- [ ] No performance degradation vs native development

## Compliance and Standards

### Relevant Standards
- **CIS Docker Benchmark**: Container security best practices
- **NIST SP 800-190**: Application Container Security Guide
- **Docker Security Best Practices**: Official Docker documentation
- **OWASP Container Security**: OWASP container security guidelines

### Compliance Checkpoints
- Non-root user execution (CIS Docker Benchmark 4.1)
- Trusted base images (CIS Docker Benchmark 4.2)
- No secrets in images (Docker Security Best Practices)
- Minimal capabilities (NIST SP 800-190)
- No privileged mode (CIS Docker Benchmark 5.4)

## Maintenance and Review

### Update Schedule
- **Base images**: Quarterly review, immediate for critical vulnerabilities
- **Packages**: Monthly security updates, quarterly full review  
- **Security requirements**: Annual review or when threats change
- **Scope document**: Update when architecture or threats change

### Security Review Triggers
- New devcontainer platform added
- Major tool or dependency update
- Security incident or near-miss
- New vulnerability class discovered
- Annual scheduled review

### Ownership
- **Security Scope**: Security Review Agent maintains
- **Requirements**: Requirements Engineer Agent with Security Review Agent collaboration
- **Implementation**: Developer Agent with security requirement adherence
- **Testing**: Tester Agent creates security-focused tests

## References

### Related Requirements
- req_0026: Development Containers for Supported Platforms
- req_0027: Development Container Secrets Management (CRITICAL)
- req_0028: Development Container Base Image Verification (HIGH)
- req_0029: Development Container Package Integrity (HIGH)
- req_0030: Development Container Privilege Restriction (HIGH)
- req_0031: Development Container Build Security (MEDIUM)

### Related Features
- feature_0005: Development Containers for Supported Platforms

### External Resources
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST SP 800-190: Application Container Security Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [OWASP Container Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Container_Security_Cheat_Sheet.html)
- [hadolint - Dockerfile Linter](https://github.com/hadolint/hadolint)

## Document History
- [2026-02-08] Initial scope document created following security review of feature_0005
- [2026-02-08] Complete STRIDE/DREAD threat model documented
- [2026-02-08] 7 security interfaces identified and analyzed
- [2026-02-08] 5 new security requirements created (req_0027–req_0031)
