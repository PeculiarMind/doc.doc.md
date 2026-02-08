# Ubuntu 22.04 LTS Development Container
# Implements security requirements: req_0027, req_0028, req_0029, req_0030, req_0031

# req_0028: Base Image Verification - Use Docker Official Image with SHA256 pin
FROM ubuntu:22.04@sha256:09506232a8004baa32c47d68f1e5c307d648fdd59f5e7eaa42aaf87914100db3

# Metadata
LABEL maintainer="doc.doc.md contributors"
LABEL description="Ubuntu 22.04 development container for doc.doc.md project"
LABEL security.no-secrets="Secrets managed via mounts and agent forwarding (req_0027)"
LABEL security.non-root="Runs as non-root user devuser UID 1000 (req_0030)"
LABEL security.verified-packages="All packages from official Ubuntu repositories with GPG verification (req_0029)"

# req_0030: Privilege Restriction - Create non-root user
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=1000

# Install packages as root (required), then switch to non-root user
# req_0029: Package Integrity - Use HTTPS and GPG verification (default for apt)
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core development tools
    bash \
    git \
    make \
    sed \
    gawk \
    grep \
    # Testing and quality tools
    shellcheck \
    jq \
    # CLI tools for metadata extraction
    file \
    coreutils \
    exiftool \
    poppler-utils \
    # Documentation tools
    pandoc \
    # Utilities
    curl \
    ca-certificates \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# req_0030: Create non-root user with sudo access for development flexibility
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# req_0030: Switch to non-root user for all subsequent operations
USER $USERNAME

# Set working directory
WORKDIR /workspace

# req_0027: NO SECRETS IN THIS DOCKERFILE
# All credentials managed via mounts and agent forwarding in devcontainer.json
# SSH keys: Mounted read-only from host ~/.ssh/
# Git credentials: Via SSH agent forwarding or credential helper
# GPG keys: Via agent forwarding

# Document security implementation
RUN echo "Security implementations:" > /home/$USERNAME/SECURITY.txt && \
    echo "- req_0027: No embedded secrets (verified via .dockerignore)" >> /home/$USERNAME/SECURITY.txt && \
    echo "- req_0028: Base image SHA256 pinned to official Docker image" >> /home/$USERNAME/SECURITY.txt && \
    echo "- req_0029: Packages from official repos with GPG verification" >> /home/$USERNAME/SECURITY.txt && \
    echo "- req_0030: Non-root user (UID $USER_UID)" >> /home/$USERNAME/SECURITY.txt && \
    echo "- req_0031: .dockerignore excludes credentials from build" >> /home/$USERNAME/SECURITY.txt

CMD ["/bin/bash"]
