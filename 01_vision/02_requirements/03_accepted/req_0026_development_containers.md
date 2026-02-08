# Requirement: Development Containers for Supported Platforms

**ID**: req_0026

## Status
State: Accepted  
Created: 2026-02-08  
Last Updated: 2026-02-08

## Overview
The project shall provide development container (devcontainer) configurations for each supported platform to ensure consistent development environments, quick onboarding, and easy cross-platform testing.

## Description
To improve developer experience and reduce environment setup friction, the system must provide devcontainer configurations for supported platforms (Ubuntu, Debian, Arch, generic Linux). Each devcontainer includes pre-configured tooling, dependencies, and common CLI tools used by plugins. This approach eliminates "works on my machine" issues, enables instant environment availability with a single command, and facilitates cross-platform testing by allowing developers to easily switch between platform environments.

Development containers provide isolated environments that prevent conflicts with the host system while ensuring consistent code quality checks and linting across all contributors. Contributors can open the repository in VS Code with the Dev Containers extension and immediately begin development without manual tool installation or configuration.

## Motivation
From the vision: "To improve developer experience and reduce environment setup friction, the project should provide development containers (devcontainers) for each supported platform." The vision section on "Developer Experience" specifically outlines goals of consistent environments, quick onboarding, platform testing capability, reproducible builds, and reduced setup time.

This requirement supports the overall project goals of remaining lightweight and composable by ensuring the development environment matches the intended runtime environment, and verifies that the toolkit works correctly across different Linux distributions.

## Category
- Type: Non-Functional (Developer Experience)
- Priority: Medium

## Acceptance Criteria

### Devcontainer Configurations
- [ ] Provide devcontainer configuration files for primary supported platforms:
  - Ubuntu (latest LTS)
  - Debian (stable)
  - Arch Linux
  - Generic Linux (minimal common base)
- [ ] Each devcontainer includes all required development tools:
  - Bash shell (appropriate version for platform)
  - Testing frameworks used by the project
  - Linters and code quality tools
  - Documentation generation tools
- [ ] Each devcontainer pre-installs common CLI tools used by plugins:
  - file, stat, md5sum/sha256sum
  - exiftool for metadata extraction
  - Platform-specific package management tools
- [ ] Development-specific conveniences are configured:
  - Git completion and helpers
  - Shell customization for development workflow
  - Debugging tools appropriate for Bash development

### Environment Consistency
- [ ] Devcontainers use locked tool versions for reproducible builds
- [ ] Configurations include consistent settings across all platform variants
- [ ] Environment variables match production deployment expectations
- [ ] Working directory structure matches expected project layout

### Developer Workflow
- [ ] Single command setup: open repository in VS Code with Dev Containers extension works immediately
- [ ] Developers can switch between platform environments for cross-platform testing easily
- [ ] Build and test commands work identically in all devcontainer environments
- [ ] Documentation clearly explains how to use devcontainers for development

### Isolation and Safety
- [ ] Devcontainers provide isolated environments preventing conflicts with host system
- [ ] Host system files are not modified by devcontainer operations
- [ ] Multiple devcontainers can run simultaneously for parallel testing

### Documentation
- [ ] README or CONTRIBUTING guide explains devcontainer usage
- [ ] Each devcontainer includes inline documentation of its configuration
- [ ] Setup instructions for VS Code Dev Containers extension are provided
- [ ] Troubleshooting guide for common devcontainer issues exists

## Related Requirements
- req_0009 (Lightweight Implementation) - devcontainers support lightweight development workflow
- req_0010 (Unix Tool Composability) - devcontainers ensure correct tools available for composability testing
- req_0007 (Tool Availability Verification) - devcontainers help verify tool availability scripts work correctly
- req_0003 (Metadata Extraction with CLI Tools) - devcontainers provide environments to test CLI tool integrations

## Transition History
- [2026-02-08] Moved from Funnel to Accepted  
-- Comment: Requirement approved for implementation
- [2026-02-08] Created and placed in Funnel by Requirements Engineer Agent  
-- Comment: New requirement derived from Developer Experience section in vision document

## Notes
This requirement addresses developer experience and environment consistency, which are critical for maintaining code quality and enabling contributions. While not directly affecting end-user functionality, devcontainers significantly reduce onboarding friction and ensure that all developers work in environments matching the intended deployment targets.

The devcontainer configurations should be maintained in the `.devcontainer/` directory with subdirectories for each platform variant (e.g., `.devcontainer/ubuntu/`, `.devcontainer/debian/`, `.devcontainer/arch/`, `.devcontainer/generic/`).
