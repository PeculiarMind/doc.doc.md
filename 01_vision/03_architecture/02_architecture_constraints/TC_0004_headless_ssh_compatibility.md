# TC-0004: Headless/SSH Environment Compatibility

**ID**: TC-0004  
**Status**: Active  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08  
**Type**: Technical Constraint

## Constraint

The system must function in headless environments accessible only via SSH or terminal, without graphical display capabilities.

## Source

Target deployment scenarios (servers, remote systems, CI/CD pipelines, Docker containers)

## Rationale

Primary use cases include server environments, automated pipelines, and remote system access where no X11/Wayland display server is available or permitted.

## Impact

**Architectural Impact**:
- Cannot depend on GUI libraries, frameworks, or windowing systems
- No interactive graphical prompts or displays
- All interaction through stdin/stdout/stderr and terminal text
- Cannot launch GUI tools even if installed

**Design Constraints**:
- Pure command-line interface (CLI)
- Text-only output and logging
- Non-interactive by default
- Suitable for automation and scripting

## Non-Negotiable Because

Target deployment environments (production servers, CI/CD agents) do not provide graphical display capabilities. Remote access is typically via SSH with no X forwarding.

## Related Constraints

- [TC-0003: User-Space Execution](TC_0003_user_space_execution.md)
- [TC-0005: File-Based State Management](TC_0005_file_based_state_management.md)
