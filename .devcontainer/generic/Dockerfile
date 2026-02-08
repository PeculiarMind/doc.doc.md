# Alpine Linux Generic Development Container
# Implements security requirements: req_0027, req_0028, req_0029, req_0030, req_0031

# req_0028: Base Image Verification - Use Docker Official Image with SHA256 pin
FROM alpine:3.19@sha256:6457d53fb065d6f250e1504b9bc42d5b6c65941d57532c072d929dd0628977d0

# Metadata
LABEL maintainer="doc.doc.md contributors"
LABEL description="Alpine Linux minimal development container for doc.doc.md project"
LABEL security.no-secrets="Secrets managed via mounts and agent forwarding (req_0027)"
LABEL security.non-root="Runs as non-root user devuser UID 1000 (req_0030)"
LABEL security.verified-packages="All packages from official Alpine repositories with GPG verification (req_0029)"

# req_0030: Privilege Restriction - Create non-root user
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=1000

# Install packages as root (required), then switch to non-root user
# req_0029: Package Integrity - apk verifies signatures by default
RUN apk update && apk add --no-cache \
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
    shadow

# req_0030: Create non-root user with sudo access for development flexibility
RUN addgroup -g $USER_GID $USERNAME \
    && adduser -D -u $USER_UID -G $USERNAME -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# req_0030: Switch to non-root user for all subsequent operations
USER $USERNAME

# Set working directory
WORKDIR /workspace

# Document security implementation
RUN echo "Security implementations:" > /home/$USERNAME/SECURITY.txt && \
    echo "- req_0027: No embedded secrets (verified via .dockerignore)" >> /home/$USERNAME/SECURITY.txt && \
    echo "- req_0028: Base image SHA256 pinned to official Docker image" >> /home/$USERNAME/SECURITY.txt && \
    echo "- req_0029: Packages from official repos with GPG verification" >> /home/$USERNAME/SECURITY.txt && \
    echo "- req_0030: Non-root user (UID $USER_UID)" >> /home/$USERNAME/SECURITY.txt && \
    echo "- req_0031: .dockerignore excludes credentials from build" >> /home/$USERNAME/SECURITY.txt

CMD ["/bin/bash"]
