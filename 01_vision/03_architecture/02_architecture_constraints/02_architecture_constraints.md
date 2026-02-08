---
title: Architecture Constraints
arc42-chapter: 2
---

# 2. Architecture Constraints

## Table of Contents

- [Overview](#overview)
- [Technical Constraints](#technical-constraints)
  - [TC-1: Bash/POSIX Shell Runtime Environment](#tc-1-bashposix-shell-runtime-environment)
  - [TC-2: No Network Access During Runtime](#tc-2-no-network-access-during-runtime)
  - [TC-3: User-Space Execution (No Root/Sudo)](#tc-3-user-space-execution-no-rootsudo)
  - [TC-4: Headless/SSH Environment Compatibility](#tc-4-headlessssh-environment-compatibility)
  - [TC-5: File-Based State Management](#tc-5-file-based-state-management)
- [Organizational Constraints](#organizational-constraints)
- [Conventions](#conventions)

## Overview
This section documents the **true architectural constraints**—external limitations, organizational boundaries, and fixed technical conditions that restrict the design space and cannot be changed by architectural decisions. These constraints represent boundaries we must work within, not features we choose to implement.

**Distinction from Requirements**: Constraints are limitations imposed upon us (platform requirements, organizational policies, technical boundaries). Requirements describe what the system should do. Design decisions describe choices we make within the constrained space.

## Technical Constraints

### TC-1: Bash/POSIX Shell Runtime Environment
- **Constraint**: The system must execute in Bash 3.x+ or POSIX-compliant shell environments commonly available on Linux, macOS, and WSL.
- **Source**: Target deployment platforms (standard UNIX-like systems)
- **Rationale**: Target users operate on standard Linux/macOS systems where Bash is the ubiquitous scripting environment. Cannot assume other runtime environments (Python, Node.js, Ruby, etc.) without increasing installation burden.
- **Impact**: Implementation language limited to shell scripting. Cannot use language features or libraries requiring compilation or runtime installation beyond standard shell utilities.
- **Non-negotiable Because**: Target platforms only guarantee Bash/POSIX shell availability without additional installations.

### TC-2: No Network Access During Runtime
- **Constraint**: The system cannot make network connections during the analysis and report generation phases. All processing must occur using only local resources.
- **Source**: Security and privacy requirements (req_0011, req_0012, req_0016)
- **Rationale**: Users may process sensitive documents in air-gapped environments, regulated industries, or offline scenarios. Data privacy policies prohibit transmitting file content or metadata to external services.
- **Impact**: 
  - Cannot use cloud-based analysis services, LLMs, or external APIs
  - Cannot fetch external resources during runtime
  - All analysis tools must be locally installed
  - Network access permitted only for tool installation and updates (user-initiated, separate phase)
- **Non-negotiable Because**: Organizational security policies and offline deployment requirements mandate local-only processing.

### TC-3: User-Space Execution (No Root/Sudo)
- **Constraint**: The system must operate entirely in user-space without requiring root privileges or sudo access.
- **Source**: Target deployment environments (shared servers, restricted user accounts, corporate workstations)
- **Rationale**: Users may not have administrative privileges on target systems. Requiring sudo would prevent usage in many enterprise and shared hosting environments.
- **Impact**:
  - Cannot install system-wide packages or modify system directories
  - Cannot access privileged system information or APIs
  - Must use user-writable directories for workspace and output
  - Tool installation prompts must guide users to userspace methods (package managers like Homebrew, apt without sudo, manual installation)
- **Non-negotiable Because**: Many target environments explicitly prohibit sudo access for security and system stability.

### TC-4: Headless/SSH Environment Compatibility
- **Constraint**: The system must function in headless environments accessible only via SSH or terminal, without graphical display capabilities.
- **Source**: Target deployment scenarios (servers, remote systems, CI/CD pipelines, Docker containers)
- **Rationale**: Primary use cases include server environments, automated pipelines, and remote system access where no X11/Wayland display server is available or permitted.
- **Impact**:
  - Cannot depend on GUI libraries, frameworks, or windowing systems
  - No interactive graphical prompts or displays
  - All interaction through stdin/stdout/stderr and terminal text
  - Cannot launch GUI tools even if installed
- **Non-negotiable Because**: Target deployment environments (production servers, CI/CD agents) do not provide graphical display capabilities.

### TC-5: File-Based State Management
- **Constraint**: State persistence must use file-based storage only; database servers or daemon processes are not available.
- **Source**: Lightweight implementation requirement and deployment environment limitations
- **Rationale**: Target environments do not run database servers. Solution must be self-contained without assuming availability of PostgreSQL, MySQL, Redis, or similar services.
- **Impact**:
  - State, metadata, and workspace data stored as JSON files
  - No ACID guarantees beyond filesystem atomicity
  - Concurrency handled through file locking mechanisms
  - Query performance limited by filesystem and text processing tools
- **Non-negotiable Because**: Cannot require users to install and maintain database servers for a lightweight analysis toolkit.

## Organizational Constraints

### OC-1: No External Service Dependencies at Runtime
- **Constraint**: The system cannot depend on availability of external services, APIs, or internet connectivity during operation.
- **Source**: Offline operation requirement (vision, req_0016) and deployment in restricted networks
- **Rationale**: Users operate in environments with intermittent connectivity, behind firewalls, in air-gapped networks, or where external service dependencies create operational risks.
- **Impact**:
  - All functionality must work offline after initial tool installation
  - Cannot rely on cloud services, SaaS platforms, or external APIs
  - Tool updates are user-initiated, separate from analysis operations
  - Documentation and help must be available locally
- **Non-negotiable Because**: Offline operation is a core deployment requirement; internet connectivity cannot be assumed.

## Summary

**Total Constraints**: 6 (5 Technical, 1 Organizational)

These constraints define immutable boundaries for architectural decisions. They represent:
- **Platform limitations**: What runtime environments provide (or don't provide)
- **Deployment requirements**: Where and how the system must operate
- **Security policies**: Privacy and network access restrictions
- **Resource availability**: What infrastructure can be assumed

**Items Removed from Previous Version** (not true constraints):
- Simplicity and Composability → Design principle in Solution Strategy
- Lightweight Design → Quality requirement (Efficiency)
- Standardized Output → Functional requirement (req_0004)
- Extensibility → Functional requirement (req_0021, req_0022)
- Tool Availability Verification → Functional requirement (req_0007, req_0008)
- Error Handling and Reliability → Quality requirement (req_0020)
- Minimal Runtime Dependencies → Quality requirement (req_0009)
- Unix Philosophy Compliance → Design principle in Solution Strategy

These items are important but represent **choices we make** (design decisions, requirements, quality goals) rather than **boundaries imposed upon us** (constraints).