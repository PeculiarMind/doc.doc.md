# Risks and Technical Debt

## Open Items from Architecture Reviews

| Source | ID | Description | Severity | Status |
|--------|----|-------------|----------|--------|
| ARCHREV_001 | DEV-001 | `install` command output includes undeclared `message` field — resolved by updating both `file/descriptor.json` and `stat/descriptor.json`. | Low | ✅ Resolved (descriptors updated) |
| ARCHREV_002 | DEV-001 | ARC_0001 pseudocode diverged from actual MIME matching implementation — resolved by updating ARC_0001 (DEBTR_002). | Low | ✅ Resolved |
| ARCHREV_002 | DEV-002 | `-o` output directory flag and directory mirroring not yet implemented (pre-existing). | Medium | ⚠️ Open — see TD-007 below |
| BUG_0005 | — | `ocrmypdf/descriptor.json` contains explicit `"dependencies"` attribute; dependencies must be derived from parameter types. | Medium | ⚠️ Backlog |

## Technical Risks

| ID | Risk | Probability | Impact | Mitigation |
|----|------|-------------|--------|------------|
| R-T01 | **Shell Script Portability** — Bash-specific constructs may fail on some shells | Medium | Medium | POSIX-compliant constructs where possible; `#!/bin/bash`; tested on Linux and macOS |
| R-T02 | **Python Version Fragmentation** — Python 3.12+ excludes older Ubuntu/Debian | Low | Medium | Version check on startup; standard library only; document minimum requirements |
| R-T03 | **MIME Type Detection Inaccuracy** — `file` command may misidentify some files | Low | Low | Standard tool, battle-tested; users can supplement with explicit extension criteria |
| R-T04 | **Plugin System Complexity** — Type-based dependency resolution not fully implemented | Medium | High | Current implementation works for simple chains; complex chains require explicit ordering |
| R-T05 | **Large Directory Performance** — Sequential processing of 100k+ files may be slow | Medium | Medium | Streaming pipeline avoids memory bloat; parallel processing deferred (TD-006) |
| R-T06 | **Filter Logic Bugs** — Complex AND/OR combinations may produce unexpected results | Medium | High | Comprehensive unit tests in place (162+ tests across three suites); dry-run option planned |
| R-T07 | **Template Injection** — Template variables could contain shell metacharacters | Low | High | Variables must be escaped before substitution; mitigated by controlled plugin output |

## Organizational Risks

| ID | Risk | Probability | Impact | Mitigation |
|----|------|-------------|--------|------------|
| R-O01 | **Single Maintainer** | High | High | Comprehensive Arc42 documentation; clean code; encourage contributions; all decisions documented |
| R-O02 | **Plugin Ecosystem Growth** — No contribution guidelines yet | Medium | Medium | Plugin developer guide planned; example plugins (`stat`, `file`, `ocrmypdf`) serve as references |

## Technical Debt

| ID | Description | Impact | Priority | Remediation |
|----|-------------|--------|----------|-------------|
| TD-001 | **Simple Template Engine** — Bash text substitution; no conditionals or loops | Low | Low | Adequate for MVP; consider Jinja2 if complex templating is required |
| TD-002 | **No Formal Plugin Dependency Resolution** — Order derived informally from parameter names; no topological sort | Medium | Medium | Implement topological sort in `plugins.sh`; add cycle detection |
| TD-003 | **Limited Error Recovery** — Basic handling in place; no comprehensive recovery strategies | Medium | Medium | Expand per-category error recovery; enhance test coverage for error scenarios |
| TD-004 | **No Configuration File Support** — All options via CLI flags only | Low | Low | Add `~/.config/doc.doc.md/config` support in a future release |
| TD-005 | **Basic Progress Indication** — Simple counter; no progress bar | Low | Low | Add visual progress bar for terminal output in a future release |
| TD-006 | **No Parallel Processing** — Sequential file processing | Medium | Low | Add parallel processing via `xargs -P` or background jobs for multi-core benefit |
| TD-007 | **Output Directory Not Implemented** — `-o` flag and directory mirroring absent | Medium | High | Implement `--output-directory` / `-o` with mirrored path generation; required by REQ_0013 |
| TD-008 | **Explicit `dependencies` in ocrmypdf descriptor** — Violates ADR-003; should be derived from parameter types | Medium | Medium | Remove `"dependencies"` key from `ocrmypdf/descriptor.json`; tracked as BUG_0005 |

## Accepted Trade-offs

| ID | Trade-off | Rationale |
|----|-----------|-----------|
| AT-001 | Bash/Python mix vs. single language | Better separation of concerns; each language used for its strengths. See ADR-001. |
| AT-002 | Tool reuse vs. custom implementation | Faster development; proven reliability; lower maintenance. See ADR-002. |
| AT-003 | Simple template engine | MVP scope; can upgrade if user demand warrants. |
| AT-004 | CLI-only interface | Fits Unix philosophy; target users comfortable with command line. |
| AT-005 | Activation state in `descriptor.json` | Simple implementation; adequate for current user base. |

## Risk Monitoring

| Indicator | Threshold | Action |
|-----------|-----------|--------|
| Processing time regression | > 2× baseline | Profile critical paths; optimize |
| Filter logic bug reports | > 2 per release | Enhance test coverage; add validation |
| Platform-specific bugs | > 1 per platform per release | Improve POSIX compliance; add platform CI |
| Template injection vulnerability | Any confirmed | Immediate patch; implement escaping |
| Plugin chain failures (type mismatch) | > 1 undetected | Implement formal dependency resolution |
