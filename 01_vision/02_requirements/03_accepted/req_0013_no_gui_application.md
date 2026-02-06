# Requirement: No GUI Application

**ID**: req_0013  
**Title**: No GUI Application  
**Status**: Accepted  
**Created**: 2026-01-31  
**Category**: Constraint

## Overview
The system shall not include or require a graphical user interface (GUI) for its operation.

## Description
The toolkit must be designed as a command-line application that operates entirely through text-based interfaces. It should not depend on graphical libraries, windowing systems, or GUI frameworks. All functionality must be accessible through command-line parameters, configuration files, and standard input/output.

## Motivation
From the vision: "Non‑Goals: Building a full GUI application."

Focusing on CLI implementation keeps the toolkit lightweight, scriptable, and suitable for server environments, CI/CD pipelines, and remote systems where GUI access is unavailable or impractical.

## Acceptance Criteria
1. The system operates entirely through command-line interfaces
2. No GUI libraries or frameworks are included as dependencies
3. The system can be used effectively over SSH or in headless environments
4. All configuration and operation can be performed through text-based files and command-line parameters
5. The system does not require X11, Wayland, or any other windowing system

## Dependencies
None

## Notes
This constraint does not prevent generating visual output formats (e.g., HTML with embedded charts) as long as the generation process itself is CLI-based.
