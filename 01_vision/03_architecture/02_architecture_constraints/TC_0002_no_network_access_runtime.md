# TC-0002: No Network Access During Runtime

**ID**: TC-0002  
**Status**: Active  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08  
**Type**: Technical Constraint

## Constraint

The system cannot make network connections during the analysis and report generation phases. All processing must occur using only local resources.

## Source

Security and privacy requirements (req_0011, req_0012, req_0016)

## Rationale

Users may process sensitive documents in air-gapped environments, regulated industries, or offline scenarios. Data privacy policies prohibit transmitting file content or metadata to external services.

## Impact

**Architectural Impact**:
- Cannot use cloud-based analysis services, LLMs, or external APIs
- Cannot fetch external resources during runtime
- All analysis tools must be locally installed
- Network access permitted only for tool installation and updates (user-initiated, separate phase)

**Design Constraints**:
- All analysis must be local
- Plugin tools must be pre-installed
- No telemetry or analytics transmission
- Complete offline operation after setup

## Non-Negotiable Because

Organizational security policies and offline deployment requirements mandate local-only processing. Many target environments operate in air-gapped or restricted network conditions.

## Related Constraints

- [TC-0001: Bash/POSIX Shell Runtime Environment](TC_0001_bash_posix_shell_runtime.md)
- [TC-0006: No External Service Dependencies](TC_0006_no_external_service_dependencies.md)
