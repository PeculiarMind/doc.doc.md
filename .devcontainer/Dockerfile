FROM ubuntu:24.04

# Create vscode user
ARG USERNAME=vscode
ARG USER_UID=1001
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install basic development tools
RUN apt-get update && apt-get install -y \
    file \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# Set the default shell to bash
ENV SHELL=/bin/bash

# Switch to vscode user
USER $USERNAME

# Set working directory
WORKDIR /workspace
