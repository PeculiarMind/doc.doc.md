# TC-0002: No Network Access During Runtime

**ID**: TC-0002  
**Status**: Active  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08

## Constraint

No network connections permitted during analysis and report generation phases.

## Source

Security and privacy requirements (req_0011, req_0012, req_0016). Users may process sensitive documents in air-gapped environments, regulated industries, or offline scenarios.

## Rationale

Data privacy policies prohibit transmitting file content or metadata to external services. Target users operate in environments where network access is restricted or prohibited during file processing.

## Impact

- Cannot use cloud-based analysis services, LLMs, or external APIs
- Cannot fetch external resources during runtime
- All analysis tools must be locally installed
- Network access permitted only for tool installation and updates (user-initiated, separate phase)

## Implementation Status

**Compliance**: ✅ COMPLIANT

**Evidence**:
- No network calls in current codebase
- No external API dependencies
- Local file operations only
- ⏳ Network access validation (to be enforced in plugin execution)

**Compliance Verification**:
```bash
# Verify no network-related commands
grep -r "curl\|wget\|http\|fetch" scripts/doc.doc.sh
# Returns: None (compliant)
```

## Implementation Approach

- Current code makes no network connections
- Future: Plugin execution will validate tool commands
- Tool installation (future feature) explicitly separate from analysis

## Future Enforcement

When implementing plugin execution:
- Validate plugin commands don't make network calls
- Reject plugins that require network access during runtime
- Document constraint in plugin development guidelines

## Compliance Verification

**Verification Method**:
```bash
# Disable network and test functionality
sudo iptables -A OUTPUT -j DROP
./scripts/doc.doc.sh --help
./scripts/doc.doc.sh -p list
sudo iptables -D OUTPUT -j DROP
```

**Expected Result**: All core functionality works without network

## Related Constraints

- [TC-0001: Bash/POSIX Shell Runtime Environment](TC_0001_bash_posix_shell_runtime.md)
- [TC-0006: No External Service Dependencies](TC_0006_no_external_service_dependencies.md)
