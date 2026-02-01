# Requirement: Installation Prompts

**ID**: req_0008  
**Title**: Installation Prompts  
**Status**: Funnel  
**Created**: 2026-01-31  
**Category**: Usability

## Overview
The system shall prompt users with installation instructions when required CLI tools are not found.

## Description
When tool availability verification detects missing CLI tools, the system must provide users with clear, actionable instructions for installing those tools. Instructions should be platform-specific when possible and guide users toward the most appropriate installation method for their environment.

## Motivation
From the vision: "Usability by providing scripts that verify required tools are installed and, if not, prompt the user to install them."

Helpful installation prompts reduce setup friction and enable users to quickly resolve dependency issues without extensive documentation research.

## Acceptance Criteria
1. For each missing tool, the system displays installation instructions appropriate for the detected platform (Linux, macOS, etc.)
2. Installation instructions include specific package names and installation commands
3. The system suggests the most common installation method for the user's platform (e.g., `apt` for Ubuntu, `brew` for macOS)
4. Instructions are displayed in a clear, easy-to-follow format
5. The system provides documentation links for tools requiring manual installation

## Dependencies
- req_0007 (Tool Availability Verification)

## Notes
Consider detecting the specific Linux distribution or OS variant to provide more precise installation commands.
