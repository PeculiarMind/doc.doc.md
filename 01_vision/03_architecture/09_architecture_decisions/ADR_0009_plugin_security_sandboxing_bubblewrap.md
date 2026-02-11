# ADR-0009: Plugin Security Sandboxing with Bubblewrap

**ID**: ADR-0009  
**Status**: Accepted  
**Created**: 2026-02-11  
**Last Updated**: 2026-02-11

## Context

Feature 0009 (Plugin Execution Engine) security review identified **Critical** vulnerabilities (Risk Score: 248) from executing untrusted plugin code directly in the system environment. Plugins can contain arbitrary code that could:

- Execute malicious commands with user privileges
- Access sensitive files outside intended scope  
- Modify system files or workspace data
- Exfiltrate confidential source code and credentials
- Install malware or backdoors
- Consume excessive system resources

The plugin architecture requires executing third-party code for extensibility, but the current trust model ("plugins as trusted code") is insufficient for security. A mandatory sandboxing solution is required to isolate plugin execution while maintaining functionality.

## Decision

Implement **mandatory plugin sandboxing using Bubblewrap (bwrap)** for all plugin execution.

All plugins must execute within Bubblewrap containers with:
- **Hard dependency**: No plugin execution without successful sandbox creation
- **Read-only access**: Plugins can only read files they are processing  
- **Temporary directory**: Plugins get dedicated temporary space for intermediate results
- **No network access**: Continue offline-first design within sandbox
- **Resource limits**: CPU and memory constraints via container limits
- **Minimal filesystem**: Only essential directories and files accessible

## Rationale

**Security Benefits**:
- **Complete Isolation**: Plugins cannot affect host system or other plugin executions
- **Controlled Filesystem Access**: Precise control over what files plugins can read/write
- **Resource Management**: Built-in protection against resource exhaustion attacks
- **Process Isolation**: Plugin processes cannot interact with host processes
- **Namespace Separation**: Network, PID, and mount namespace isolation

**Technical Advantages**:
- **Linux Standard**: Bubblewrap is standard sandboxing technology used by Flatpak
- **Lightweight**: Minimal overhead compared to full containers
- **Flexible**: Granular control over sandbox permissions
- **Reliable**: Mature technology with active security maintenance
- **Integration**: Works seamlessly with existing shell-based architecture

**Implementation Feasibility**:
- **Bash Compatible**: Can be invoked directly from shell scripts
- **Minimal Dependencies**: Single binary dependency (bwrap)
- **Portable**: Available on all major Linux distributions
- **Performance**: Low overhead for typical plugin workloads

## Implementation Details

### Bubblewrap Command Structure
```bash
bwrap \
  --ro-bind / / \                    # Read-only root filesystem
  --bind "$temp_dir" /tmp \          # Writable temporary directory
  --bind "$file_path" "$file_path" \  # Read access to source file
  --unshare-net \                    # No network access
  --unshare-pid \                    # PID namespace isolation
  --die-with-parent \                # Cleanup on parent exit
  --new-session \                    # Process session isolation
  --proc /proc \                     # Minimal /proc access
  --dev /dev \                       # Minimal /dev access
  "$plugin_executable" "$file_path"
```

### Hard Dependency Management
- **Pre-flight Check**: Verify `bwrap` availability before any plugin execution
- **Graceful Failure**: Clear error messages if Bubblewrap unavailable
- **Installation Guide**: Document Bubblewrap installation for all supported platforms
- **Feature Gate**: Plugin execution entirely disabled without sandbox capability

### Filesystem Access Controls
- **Source File**: Read-only bind mount of file being processed
- **Temporary Directory**: Unique writable directory per plugin execution
- **Plugin Directory**: Read-only access to plugin's own files
- **System Binaries**: Read-only access to `/bin`, `/usr/bin` for CLI tool dependencies
- **No Home Access**: User's home directory not accessible within sandbox
- **No Network**: Offline execution enforced by `--unshare-net`

### Resource Management
- **Timeout Enforcement**: Existing 30-second timeout still applies
- **Memory Limits**: Future enhancement via `--setrlimit` when needed
- **Process Limits**: Built-in via PID namespace isolation
- **Cleanup**: Automatic on timeout or parent process termination

## Consequences

### Positive
- **Security**: Eliminates Critical and High risk plugin vulnerabilities
- **Reliability**: Plugin failures cannot affect system stability
- **Trust Model**: Plugins can be treated as untrusted code safely
- **Audit Trail**: Clear separation between trusted toolkit and untrusted plugins
- **Development**: Plugin developers can focus on functionality over security

### Negative  
- **Dependency**: Hard requirement on Bubblewrap installation
- **Complexity**: Additional layer in plugin execution pipeline
- **Debugging**: Plugin debugging requires understanding sandbox environment
- **Compatibility**: May require plugin modifications if they expect full system access
- **Performance**: Minimal overhead from sandbox creation/teardown

### Neutral
- **Plugin Interface**: No changes required to plugin descriptor format
- **Error Handling**: Existing error handling mechanisms still apply
- **Platform Support**: Linux-specific technology (acceptable given platform strategy)

## Alternative Considered

### User-level Permission Restrictions
**Rejected**: Insufficient isolation, plugins still have broad filesystem access

### Full Container Solutions (Docker/Podman)
**Rejected**: Excessive overhead, complex dependency management, not designed for ephemeral execution

### chroot Sandboxing
**Rejected**: Modern vulnerabilities, less secure than namespace-based approaches

### No Sandboxing (Plugin Trust Model)
**Rejected**: Unacceptable security risk identified in security review

## Verification

### Functionality Tests
- [ ] Plugin executes successfully within Bubblewrap sandbox
- [ ] Plugin can read source file through read-only bind mount
- [ ] Plugin can write to temporary directory
- [ ] Plugin cannot access files outside permitted scope
- [ ] Plugin execution fails gracefully when Bubblewrap unavailable

### Security Tests  
- [ ] Plugin cannot read files outside source file and plugin directory
- [ ] Plugin cannot write outside temporary directory
- [ ] Plugin cannot execute network operations
- [ ] Plugin cannot access host processes or system resources
- [ ] Plugin cannot persist changes beyond execution scope
- [ ] Malicious plugin attempts logged and blocked

### Performance Tests
- [ ] Sandbox overhead remains under 100ms per plugin execution
- [ ] Multiple concurrent plugin executions handled correctly
- [ ] Resource cleanup on timeout and failure scenarios

## Related Decisions

- **ADR-0003**: Data-Driven Plugin Orchestration → Enhanced by secure execution
- **ADR-0010**: Plugin-Toolkit Interface Architecture → Defines the controlled interface
- **TC-0003**: User Space Execution → Enhanced with container-level isolation
- **TC-0007**: Single User Operator Trust Model → Plugins now truly untrusted

## Related Requirements

- req_0021: Plugin Architecture → Security requirements addressed
- req_0048: Command Injection Prevention → Comprehensive mitigation
- req_0053: Plugin Validation → Enhanced with execution-level controls
- req_0047: Path Traversal Prevention → Container-level prevention

## Security Controls Addressed

- **NO-001 [CRITICAL]**: Environment Data Exposure → Controlled environment isolation
- **NO-002 [CRITICAL]**: Plugin Descriptor Security → Execution-level validation
- **NO-003 [CRITICAL]**: Command Injection → Process isolation prevents impact
- **NO-004 [HIGH]**: Resource DoS → Container resource limits
- **NO-005-007 [HIGH]**: Workspace Security → Filesystem access control

## Documentation Updates Required

- **Plugin Development Guide**: Update with sandboxing considerations
- **Installation Instructions**: Include Bubblewrap installation steps
- **Troubleshooting Guide**: Sandbox-related error scenarios
- **Security Compliance**: Document how sandboxing addresses security requirements

## Implementation Priority

**Critical**: Must be implemented before Feature 0009 development begins. Plugin execution security is a prerequisite for the orchestration engine.