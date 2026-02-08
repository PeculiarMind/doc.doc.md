# Requirement: Development Container Privilege Restriction

**ID**: req_0030

## Status
State: Accepted  
Created: 2026-02-08  
Last Updated: 2026-02-08

## Overview
Development containers shall run as non-root users with minimal necessary Linux capabilities. Privileged mode and unnecessary capabilities shall be prohibited. Host filesystem mounts shall be limited to project directory.

## Description
To prevent privilege escalation and limit the impact of container compromise, development containers must operate with minimal privileges. Containers shall run as non-root users both during build and runtime, eliminating an entire class of privilege escalation vulnerabilities.

Linux capabilities that enable privileged operations (CAP_SYS_ADMIN, CAP_NET_ADMIN, etc.) shall be dropped unless explicitly required and documented. The Docker privileged mode (`--privileged`) which disables most container isolation shall never be used for development containers.

Host filesystem access shall be restricted to the minimum required for development (typically just the project directory), preventing accidental or malicious modification of host system files.

## Motivation
**Security Risk Assessment (STRIDE/DREAD)**:
- **Threat**: Elevation of Privilege - Root container + kernel vulnerability = host root access
- **Secondary Threat**: Tampering - Root container can modify system files via misconfigured mounts
- **Risk Score**: 205 (HIGH)
  - DREAD Likelihood: 7.6/10
  - Damage: 9/10 (complete host system compromise)
  - CIA Classification: Confidential (host system access)

From security review: "Containers running as root or with excessive capabilities increase risk of host compromise. Root container combined with kernel vulnerability provides complete host system access. Privileged containers disable isolation entirely, eliminating the security boundary."

## Category
- Type: Security (Development Environment - Isolation)
- Priority: High

## Acceptance Criteria

### Non-Root User Requirements
- [ ] Dockerfile creates and uses non-root user (via `USER` directive)
- [ ] Non-root user has appropriate UID/GID (typically 1000 or matching host user)
- [ ] `devcontainer.json` specifies `remoteUser` as non-root user
- [ ] Container processes run as non-root user (verify with `docker exec <container> whoami`)
- [ ] Non-root user has necessary permissions for development tasks (project directory write)
- [ ] Documentation explains non-root user rationale and configuration

### Capability Restrictions
- [ ] Unnecessary Linux capabilities dropped (use `--cap-drop` or `securityOpt`)
- [ ] No `CAP_SYS_ADMIN` unless explicitly required and documented
- [ ] No `CAP_NET_ADMIN` unless networking features required
- [ ] No `CAP_SYS_PTRACE` unless debugging features required
- [ ] Capabilities documented if any must be retained
- [ ] `--cap-drop=ALL` used as baseline, then selectively add required capabilities

### Privileged Mode Prohibition
- [ ] NO use of `--privileged` flag in container configuration
- [ ] NO use of `privileged: true` in devcontainer.json or docker-compose
- [ ] Documentation explicitly states privileged mode is prohibited
- [ ] Alternative approaches documented if privileged features needed

### Security Options
- [ ] `no-new-privileges` security option enabled
- [ ] AppArmor or SELinux profiles used where available (platform-dependent)
- [ ] Security options documented in devcontainer configuration

### Host Filesystem Mount Restrictions
- [ ] Mounts limited to project directory: `/workspace` or similar
- [ ] NO mount of entire home directory (`/home/user`)
- [ ] NO mount of sensitive host paths: `/etc`, `/root`, `/var`, `/sys`, `/proc`
- [ ] NO mount of Docker socket `/var/run/docker.sock` unless required and documented
- [ ] Sensitive credential directories mounted read-only: `~/.ssh` (readonly)
- [ ] Mount specifications documented with security rationale

### User Namespace Mapping
- [ ] User namespace remapping considered (advanced, platform-dependent)
- [ ] Documentation includes guidance on user namespace benefits
- [ ] UID/GID mapping documented for file ownership clarity

## Related Requirements
- req_0026 (Development Containers for Supported Platforms) - parent requirement
- req_0027 (Development Container Secrets Management) - credential security depends on isolation
- req_0031 (Development Container Build Security) - complementary build-time security

## Related Security Scope
- `01_vision/04_security/02_scopes/01_development_container_security.md` - Container isolation interfaces

## Transition History
- [2026-02-08] Moved from Funnel to Accepted  
-- Comment: High priority security requirement approved for implementation
- [2026-02-08] Created and placed in Funnel by Security Review Agent  
-- Comment: High priority security requirement identified during feature_0005 security review (Risk Score: 205)

## Notes
Container privilege restriction implements defense-in-depth. Even if attacker gains code execution within container, privilege restrictions limit impact:

**Defense Layers**:
1. **Non-root user**: Prevents many local privilege escalation exploits
2. **Capability dropping**: Removes dangerous kernel features
3. **Mount restrictions**: Limits filesystem access
4. **no-new-privileges**: Prevents setuid binary exploitation
5. **Security profiles**: Adds mandatory access control (AppArmor/SELinux)

**Why Non-Root Matters**:
- Many container escape CVEs require root in container as starting point
- Prevents modification of root-owned files on host (if mounted)
- Limits impact of vulnerable/malicious tools installed in container
- Aligns with principle of least privilege

**Example Dockerfile** (Non-root user):
```dockerfile
FROM ubuntu:22.04@sha256:...

# Create non-root user with specific UID/GID
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install packages as root
RUN apt-get install -y bash git jq shellcheck

# Switch to non-root user for all subsequent commands
USER $USERNAME

WORKDIR /workspace
```

**Example devcontainer.json** (Security options):
```json
{
  "name": "Secure Dev Container",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "remoteUser": "devuser",
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind",
    "source=${localEnv:HOME}/.ssh,target=/home/devuser/.ssh,type=bind,readonly",
    "source=${localEnv:HOME}/.gitconfig,target=/home/devuser/.gitconfig,type=bind,readonly"
  ],
  "runArgs": [
    "--cap-drop=ALL",
    "--security-opt=no-new-privileges",
    "--security-opt=apparmor=docker-default"
  ],
  "containerEnv": {
    "SSH_AUTH_SOCK": "${localEnv:SSH_AUTH_SOCK}"
  }
}
```

**Linux Capabilities Reference** (Common dangerous capabilities to avoid):
- `CAP_SYS_ADMIN`: Nearly equivalent to root (mount, namespace manipulation)
- `CAP_NET_ADMIN`: Network control (can intercept traffic)
- `CAP_SYS_PTRACE`: Debug other processes (can inject code)
- `CAP_SYS_MODULE`: Load kernel modules (kernel-level access)
- `CAP_DAC_OVERRIDE`: Bypass file permissions
- `CAP_CHOWN`: Change file ownership
- `CAP_SETUID/SETGID`: Change user/group IDs

**Safe Capabilities** (Usually acceptable for development):
- `CAP_NET_BIND_SERVICE`: Bind to privileged ports (<1024) - useful for dev servers
- `CAP_SETFCAP`: Set file capabilities (rarely needed)

**Best Practice - Drop All, Add Back Selectively**:
```json
"runArgs": [
  "--cap-drop=ALL",
  "--cap-add=NET_BIND_SERVICE"  // Only if dev server needs port 80/443
]
```

**Docker Socket Mounting Warning**:
Mounting `/var/run/docker.sock` gives container full control over Docker daemon, effectively root on host:
```json
// ❌ DANGEROUS - Avoid unless absolutely necessary
"mounts": [
  "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
]
```
If Docker-in-Docker needed, use alternatives:
- Docker-outside-Docker with restricted permissions
- Dedicated Docker service container
- Kaniko or buildah for rootless builds

**no-new-privileges Explanation**:
The `no-new-privileges` flag prevents processes from gaining new privileges, specifically preventing:
- Setuid/setgid binaries from escalating privileges
- File capabilities from granting additional capabilities
- Useful protection even with non-root user

**Verification Commands**:
```bash
# Check container user
docker exec <container> whoami
# Should output: devuser (not root)

# Check capabilities
docker exec <container> capsh --print
# Should show minimal capability set

# Check security options
docker inspect <container> | jq '.[0].HostConfig.SecurityOpt'
# Should show: ["no-new-privileges", "apparmor=docker-default"]

# Check mounts
docker inspect <container> | jq '.[0].Mounts'
# Review mount sources and types
```

**Sudo in Containers**:
Non-root user with passwordless sudo is acceptable for development containers:
- Allows installation of additional packages during development
- Still provides better security than running as root by default
- Requires explicit `sudo` command, making privilege use visible
- Can be logged for auditing

**File Ownership Considerations**:
Files created in container with UID 1000 appear as UID 1000 on host. Ensure:
- Container user UID matches host user UID for seamless file ownership
- Or use user namespace remapping for automatic translation
- Document file ownership behavior for developers
