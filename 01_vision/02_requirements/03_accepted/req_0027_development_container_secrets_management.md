# Requirement: Development Container Secrets Management

**ID**: req_0027

## Status
State: Accepted  
Created: 2026-02-08  
Last Updated: 2026-02-08

## Overview
Development containers shall NOT contain embedded secrets. All authentication credentials (SSH keys, Git credentials, GPG keys, API tokens) shall be provided via secure mount points, agent forwarding, or credential helpers.

## Description
To prevent credential exposure through container images, development containers must implement secure secrets management practices. Secrets such as SSH private keys, GPG signing keys, Git credentials, and API tokens shall never be copied into container images or Dockerfile layers where they could be extracted.

Instead, credentials shall be:
- Mounted from host filesystem with appropriate permissions (read-only where applicable)
- Provided via agent forwarding (SSH agent, GPG agent)
- Managed through credential helpers that don't persist in container filesystem
- Excluded from container build context via `.dockerignore`

This requirement applies to both the container build process (Dockerfile) and runtime configuration (devcontainer.json). All container images and Dockerfiles must be scanned to detect accidentally included secrets before use.

## Motivation
**Security Risk Assessment (STRIDE/DREAD)**:
- **Threat**: Information Disclosure - Secrets embedded in Dockerfile or container image layers
- **Risk Score**: 352 (CRITICAL)
  - DREAD Likelihood: 8.8/10
  - Damage: 10/10 (complete identity theft, repository access, code signing compromise)
  - CIA Classification: Highly Confidential (authentication credentials)
  
From security review: "Once secrets are in image layers, they are permanently accessible to anyone with image access. Compromised credentials enable complete impersonation of the developer, unauthorized repository access, and forged commits if signing keys are exposed."

This requirement prevents the highest-risk security threat identified in the development container security review.

## Category
- Type: Security (Development Environment)
- Priority: Critical

## Acceptance Criteria

### Dockerfile Requirements
- [ ] No secrets in `COPY`, `ADD`, `RUN`, `ENV`, or `ARG` commands
- [ ] No hardcoded credentials, API keys, tokens, or passwords anywhere in Dockerfile
- [ ] Dockerfile documentation clearly states secret handling approach
- [ ] No installation steps that require embedded credentials

### Container Configuration Requirements
- [ ] SSH keys mounted from host `~/.ssh/` directory, NOT copied into image
- [ ] SSH agent forwarding configured in devcontainer.json (`SSH_AUTH_SOCK` environment variable)
- [ ] Git credentials use credential helper or SSH agent forwarding (no inline credentials)
- [ ] GPG keys use agent forwarding for commit signing, NOT copied into image
- [ ] Private tokens/API keys (if needed) provided via environment variables from host, NOT embedded

### Build Context Exclusions
- [ ] `.dockerignore` file present and configured
- [ ] `.dockerignore` excludes: `.ssh/`, `.gnupg/`, `.aws/`, `.azure/`, `*.key`, `*.pem`, `*.crt`, `*.p12`, `*.pfx`
- [ ] `.dockerignore` excludes: `secrets/`, `.env`, `.env.local`, credential files
- [ ] Build process documented to verify `.dockerignore` effectiveness

### Secret Scanning
- [ ] Automated or manual secret scanning process defined for Dockerfiles
- [ ] Container images scanned for accidentally included secrets before use
- [ ] Secret scanning covers private keys, tokens, credentials, certificates
- [ ] Process documented for handling discovered secrets (revocation, rotation)

### Documentation
- [ ] Secure credential handling procedures documented in devcontainer README
- [ ] Examples provided showing correct SSH agent forwarding configuration
- [ ] Git credential helper setup documented
- [ ] GPG agent forwarding setup documented
- [ ] Warning messages about NOT copying secrets into containers

### Mount Configuration
- [ ] SSH directory mounted read-only: `source=${localEnv:HOME}/.ssh,target=/home/user/.ssh,type=bind,readonly`
- [ ] Git config mounted appropriately (read-only acceptable)
- [ ] No secrets directories mounted as read-write unless explicitly justified
- [ ] Mount permissions documented with security rationale

## Related Requirements
- req_0026 (Development Containers for Supported Platforms) - parent requirement
- req_0031 (Development Container Build Security) - complementary build-time security

## Related Security Scope
- `01_vision/04_security/02_scopes/01_development_container_security.md` - Host-to-container interfaces

## Transition History
- [2026-02-08] Moved from Funnel to Accepted  
-- Comment: Critical security requirement approved for implementation
- [2026-02-08] Created and placed in Funnel by Security Review Agent  
-- Comment: Critical priority security requirement identified during feature_0005 security review (Risk Score: 352)

## Notes
This is the HIGHEST PRIORITY security requirement for development containers. Credential exposure through container images has catastrophic consequences:
- Complete developer identity theft
- Unauthorized access to all repositories accessible with exposed keys
- Ability to forge signed commits if GPG keys exposed
- Persistent exposure (secrets in layers remain accessible indefinitely)

**Implementation is MANDATORY before deploying any development container configurations.**

**Common Mistakes to Avoid**:
1. Using `COPY .ssh/ /home/user/.ssh/` in Dockerfile
2. Setting `ENV GIT_TOKEN=xxx` with real tokens
3. Running `RUN ssh-keygen` and leaving keys in image
4. Forgetting to add sensitive files to `.dockerignore`
5. Using `ADD` with authenticated URLs that expose tokens

**Correct Approach Example** (devcontainer.json):
```json
{
  "remoteUser": "devuser",
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/devuser/.ssh,type=bind,readonly",
    "source=${localEnv:HOME}/.gitconfig,target=/home/devuser/.gitconfig,type=bind,readonly"
  ],
  "remoteEnv": {
    "SSH_AUTH_SOCK": "${localEnv:SSH_AUTH_SOCK}"
  }
}
```

**Secret Scanning Tools** (for reference):
- `git-secrets` (AWS secret scanner)
- `truffleHog` (general secret scanner)
- `gitleaks` (git repository scanner)
- Manual inspection: `docker history <image>` to review layers
