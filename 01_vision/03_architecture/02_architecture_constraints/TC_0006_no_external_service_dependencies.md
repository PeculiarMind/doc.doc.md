# TC-0006: No External Service Dependencies at Runtime

**ID**: TC-0006  
**Status**: Active  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08  
**Type**: Organizational Constraint

## Constraint

The system cannot depend on availability of external services, APIs, or internet connectivity during operation.

## Source

Offline operation requirement (vision, req_0016) and deployment in restricted networks

## Rationale

Users operate in environments with intermittent connectivity, behind firewalls, in air-gapped networks, or where external service dependencies create operational risks.

## Impact

**Architectural Impact**:
- All functionality must work offline after initial tool installation
- Cannot rely on cloud services, SaaS platforms, or external APIs
- Tool updates are user-initiated, separate from analysis operations
- Documentation and help must be available locally

**Design Constraints**:
- Embedded help and documentation
- Local plugin discovery and execution
- No phone-home or telemetry
- Self-contained operation model

## Exception

**Tool Installation Phase**: Network access permitted for tool installation and updates. This is explicitly user-initiated and separate from analysis operations.

## Non-Negotiable Because

Offline operation is a core deployment requirement; internet connectivity cannot be assumed. External dependencies create availability risks and violate security requirements.

## Related Constraints

- [TC-0002: No Network Access During Runtime](TC_0002_no_network_access_runtime.md)
- [TC-0005: File-Based State Management](TC_0005_file_based_state_management.md)
