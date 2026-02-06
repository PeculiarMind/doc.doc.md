# Requirement: Plugin Listing

**ID**: req_0024

## Status
State: Accepted  
Created: 2026-02-06  
Last Updated: 2026-02-06

## Overview
The system shall provide a command-line option to list all available plugins and their capabilities.

## Description
Users must be able to query the system to discover which plugins are installed, active, and available for use. The listing should display plugin metadata including name, description, consumed data, provided data, and active status. This enables users to understand available analysis capabilities without examining plugin directories or descriptor files directly.

## Motivation
From the vision: "Uses `-p list` option to list available plugins and their capabilities."

Plugin listing is essential for usability and discoverability, especially as users add custom plugins or work in different environments with varying plugin availability.

## Category
- Type: Functional
- Priority: High

## Acceptance Criteria
- [ ] The system accepts a `-p list` or `--plugins list` command-line option
- [ ] When invoked, the system scans the plugin directory and discovers all plugin descriptors
- [ ] The listing displays for each plugin: name, description, active status
- [ ] The listing indicates which plugins are installed vs. available but not installed
- [ ] The listing shows what data each plugin consumes and provides
- [ ] The output is human-readable and well-formatted
- [ ] The listing completes quickly (under 2 seconds for typical installations)
- [ ] Invalid or malformed plugin descriptors are reported with clear error messages

## Related Requirements
- req_0022 (Plugin-based Extensibility) - provides plugin system being listed
- req_0023 (Data-driven Execution Flow) - plugins listed show their data dependencies

## Transition History
- [2026-02-06] Moved from Funnel to Accepted
  - Comment: Requirement directly derived from vision document. Essential for plugin discoverability and usability.
- [2026-02-06] Created in Funnel by Requirements Engineer Agent
  - Comment: Gap identified during lifecycle review. Explicitly mentioned in vision but no requirement existed.
