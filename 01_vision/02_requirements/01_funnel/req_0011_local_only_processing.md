# Requirement: Local-Only Processing

**ID**: req_0011  
**Title**: Local-Only Processing  
**Status**: Funnel  
**Created**: 2026-01-31  
**Category**: Constraint

## Overview
The system shall perform all text analysis, metadata extraction, and content processing exclusively using local tools without transmitting data to external services.

## Description
All analysis operations must be performed locally on the user's machine using locally-installed CLI tools. The system must never transmit file content, metadata, or any sensitive information to online services, APIs, LLMs, or external processing platforms. This ensures data privacy, security, and compliance with organizational policies regarding sensitive information.

## Motivation
From the vision: "Process data locally and offline: All text analysis, metadata extraction, and content processing must be performed exclusively with local tools. No file content or sensitive data may be transmitted to online tools, LLMs, or external services."

Local-only processing is essential for protecting sensitive data, complying with privacy regulations, and enabling use in air-gapped or restricted network environments.

## Acceptance Criteria
1. The system does not make any network connections during the analysis phase
2. All CLI tools invoked for analysis operate locally without network dependencies
3. No file content or metadata is transmitted to external APIs, services, or cloud platforms
4. The system can complete full analysis workflows in completely offline environments
5. Code review and testing confirm absence of network calls during analysis operations

## Dependencies
- req_0003 (Metadata Extraction with CLI Tools)

## Notes
This constraint explicitly excludes online AI services, cloud analysis platforms, and external processing APIs. Network access is only permitted for tool installation and updates (see req_0012).
