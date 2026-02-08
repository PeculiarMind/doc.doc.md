# TC-0006: No External Service Dependencies at Runtime

**ID**: TC-0006  
**Status**: Active  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08

## Constraint

The system cannot depend on availability of external services, APIs, or internet connectivity during operation.

## Source

Offline operation requirement (vision, req_0016) and deployment in restricted networks. Users operate in environments with intermittent connectivity, behind firewalls, or in air-gapped networks.

## Rationale

External service dependencies create operational risks and prevent usage in restricted network environments. Offline operation is a core deployment requirement.

## Impact

- All functionality must work offline after initial tool installation
- Cannot rely on cloud services, SaaS platforms, or external APIs
- Tool updates are user-initiated, separate from analysis operations
- Documentation and help must be available locally

## Implementation Status

**Compliance**: ✅ COMPLIANT

**Evidence**:
- Offline-capable design
- No cloud service dependencies
- All processing local
- Help/documentation embedded in script

**Implementation Details**:
- Help text in script (`show_help()`)
- Version information embedded
- Plugin discovery from local filesystem
- Future: All tools must be locally installed

## Compliance Verification

**Verification Method**:
```bash
# Disable network and test core functionality
sudo iptables -A OUTPUT -j DROP
./scripts/doc.doc.sh --help     # Should work
./scripts/doc.doc.sh -p list     # Should work
./scripts/doc.doc.sh --version   # Should work
sudo iptables -D OUTPUT -j DROP
```

**Expected Result**: All core operations succeed offline

## Exception

**Tool Installation Phase**: Network access permitted for tool installation and updates (explicitly user-initiated, separate from analysis operations).

## Related Constraints

- [TC-0002: No Network Access During Runtime](TC_0002_no_network_access_runtime.md)
- [TC-0005: File-Based State Management](TC_0005_file_based_state_management.md)
