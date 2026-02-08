# TC-0004: Headless/SSH Environment Compatibility

**ID**: TC-0004  
**Status**: Active  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08

## Constraint

The system must function in headless environments (SSH, no GUI).

## Source

Target deployment scenarios (servers, remote systems, CI/CD pipelines, Docker containers) where no graphical display capabilities are available.

## Rationale

Primary use cases include server environments, automated pipelines, and remote system access where no X11/Wayland display server is available or permitted.

## Impact

- Cannot depend on GUI libraries, frameworks, or windowing systems
- No interactive graphical prompts or displays
- All interaction through stdin/stdout/stderr and terminal text
- Cannot launch GUI tools even if installed

## Implementation Status

**Compliance**: ✅ COMPLIANT

**Evidence**:
- Command-line interface only
- No GUI dependencies
- All output to stdout/stderr (text-based)
- No interactive prompts requiring GUI

**Implementation Details**:
- Pure terminal interaction
- No ncurses, dialog, or TUI libraries
- Suitable for cron/systemd execution
- Compatible with CI/CD pipelines

## Compliance Verification

**Verification Method**:
```bash
# Test over SSH without X11 forwarding
ssh user@remote "./scripts/doc.doc.sh --help"
ssh user@remote "./scripts/doc.doc.sh -p list"

# Test in headless container
docker run --rm -v $(pwd):/workspace ubuntu:latest /workspace/scripts/doc.doc.sh --help
```

**Expected Result**: Works correctly without display server

## Related Constraints

- [TC-0003: User-Space Execution](TC_0003_user_space_execution.md)
- [TC-0005: File-Based State Management](TC_0005_file_based_state_management.md)
