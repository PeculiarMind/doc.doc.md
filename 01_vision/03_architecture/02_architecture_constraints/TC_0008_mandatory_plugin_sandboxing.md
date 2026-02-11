# TC-0008: Mandatory Plugin Sandboxing

**ID**: TC-0008  
**Status**: Active  
**Created**: 2026-02-11  
**Source**: Security Review of Feature 0009 Plugin Execution Engine

## Constraint

**All plugin execution MUST occur within Bubblewrap sandboxes with NO exceptions.**

## Rationale

Security review of the Plugin Execution Engine identified **Critical** security vulnerabilities (Risk Score: 248) from executing untrusted plugin code directly in the system environment. Plugin execution represents the highest risk attack vector in the system architecture.

**Security Imperatives:**
- Plugins contain arbitrary third-party code that cannot be fully validated
- Plugin vulnerabilities could compromise the entire host system
- Multiple plugins executing without isolation create cross-contamination risks
- Resource exhaustion attacks require container-level protection
- Filesystem isolation essential to prevent data exfiltration

## Technical Requirements

### Hard Dependencies
- **Bubblewrap Availability**: System MUST have `bwrap` binary available
- **Dependency Check**: Plugin execution MUST fail if Bubblewrap unavailable
- **No Fallback**: No alternative non-sandboxed execution mode permitted

### Sandbox Configuration
- **Read-Only Root**: All system directories mounted read-only
- **Controlled File Access**: Only explicit file paths accessible to plugins
- **Temporary Workspace**: Dedicated writable temporary directory per execution
- **Network Isolation**: No network access (`--unshare-net`)
- **Process Isolation**: PID namespace isolation (`--unshare-pid`)
- **Resource Cleanup**: Automatic cleanup on parent process termination

### Implementation Standards
```bash
# Required Bubblewrap invocation pattern
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

## Quality Attributes Impacted

### Security (PRIMARY)
- **Confidentiality**: Prevents plugin access to sensitive files
- **Integrity**: Plugins cannot modify system files or other plugin data
- **Availability**: Resource limits prevent denial-of-service attacks

### Reliability  
- **Fault Isolation**: Plugin crashes cannot affect toolkit or other plugins
- **Resource Protection**: Container limits prevent resource exhaustion
- **Clean State**: Each plugin execution starts with clean sandbox environment

### Performance
- **Overhead**: ~50-100ms sandbox setup overhead per plugin execution (acceptable)
- **Resource Usage**: Container overhead minimal for typical plugin workloads
- **Cleanup**: Automatic resource cleanup prevents accumulation

## Platform Constraints

### Required Platforms
- **Linux**: Native Bubblewrap support (primary target)
- **WSL**: Windows Subsystem for Linux with container support
- **macOS**: Future consideration (alternative sandboxing technology needed)

### Installation Requirements
- **Ubuntu/Debian**: `sudo apt install bubblewrap`
- **RHEL/Fedora**: `sudo dnf install bubblewrap` 
- **Arch**: `sudo pacman -S bubblewrap`
- **Development Container**: Pre-installed in development environment

## Compliance Verification

### Pre-execution Checks
```bash
# Required validation before any plugin execution
if ! command -v bwrap >/dev/null 2>&1; then
    log "CRITICAL" "SECURITY" "Bubblewrap not available - plugin execution disabled"
    exit 1
fi

# Test sandbox creation
if ! bwrap --ro-bind / / true 2>/dev/null; then
    log "CRITICAL" "SECURITY" "Bubblewrap sandbox creation failed"
    exit 1
fi
```

### Runtime Validation
- Every plugin execution MUST use Bubblewrap wrapper
- Sandbox creation failure MUST terminate plugin execution
- Plugin execution logs MUST include sandbox configuration

### Security Audit
- Code review MUST verify no direct plugin execution paths
- Penetration testing MUST attempt sandbox escape scenarios  
- Security compliance scan MUST validate Bubblewrap usage

## Documentation Requirements

### User Documentation
- Installation guide MUST include Bubblewrap setup instructions
- Troubleshooting guide MUST cover sandbox-related errors
- Plugin development guide MUST explain sandbox implications

### Developer Documentation  
- Architecture documentation MUST describe sandboxing rationale
- Plugin API specification MUST define sandbox limitations
- Security documentation MUST detail sandbox configuration

## Exceptions

**No exceptions permitted.** Plugin execution without sandboxing creates unacceptable security risk.

### Future Considerations
- Alternative sandboxing technologies (e.g., gVisor, Kata) as Bubblewrap alternatives
- Enhanced sandbox configurations for specific plugin types
- Container runtime integration for advanced use cases

## Related Architecture

- **ADR-0009**: Plugin Security Sandboxing with Bubblewrap → Implementation decision
- **ADR-0010**: Plugin-Toolkit Interface Architecture → Complementary security control
- **TC-0003**: User Space Execution → Enhanced with container-level isolation
- **TC-0007**: Single User Operator Trust Model → Plugins now properly untrusted

## Validation Criteria

### Functional
- [ ] All plugin executions use Bubblewrap sandbox
- [ ] Bubblewrap dependency detection works correctly
- [ ] Sandbox creation failures handled gracefully
- [ ] Plugin cleanup works in all execution scenarios

### Security  
- [ ] Plugin cannot read files outside permitted scope
- [ ] Plugin cannot write outside temporary directory
- [ ] Plugin cannot access network resources
- [ ] Plugin cannot escape sandbox environment
- [ ] Malicious plugin attempts logged and blocked

### Performance
- [ ] Sandbox overhead under 100ms per execution
- [ ] Resource usage acceptable for concurrent plugin execution
- [ ] Memory cleanup prevents resource leakage

## Implementation Status

**Status**: Required for Feature 0009 Plugin Execution Engine  
**Priority**: Critical - blocking requirement  
**Dependencies**: Bubblewrap installation in development and deployment environments

---
**Compliance**: This constraint is **mandatory** and **non-negotiable** for security reasons.