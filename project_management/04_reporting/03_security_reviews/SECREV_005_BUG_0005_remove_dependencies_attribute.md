# Security Review: BUG_0005 — Remove Explicit Dependencies Attribute from Plugin Descriptors

- **ID:** SECREV_005
- **Created at:** 2026-03-10
- **Created by:** security.agent
- **Work Item:** [BUG_0005](../../03_plan/02_planning_board/06_done/BUG_0005_plugin_descriptor_explicit_dependencies_attribute.md)
- **Status:** No Issues Found

## TOC

1. [Reviewed Scope](#reviewed-scope)
2. [Security Concept Reference](#security-concept-reference)
3. [Assessment Methodology](#assessment-methodology)
4. [Findings](#findings)
5. [Threat Model](#threat-model)
6. [Recommendations](#recommendations)
7. [Conclusion](#conclusion)

## Reviewed Scope

| File | Change | Purpose |
|------|--------|---------|
| `doc.doc.md/plugins/ocrmypdf/descriptor.json` | Removed `"dependencies"` field | Eliminates explicit dependency declaration; derivation moved to runtime |
| `doc.doc.sh` — `cmd_tree()` | Rewritten dependency logic | Derives plugin dependencies from output→input parameter name matching |

## Security Concept Reference

- [Security Concept — Scope 3: Plugin System Architecture](../../02_project_vision/04_security_concept/01_security_concept.md)
- [REQ_SEC_001: Input Validation and Sanitization](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_001_input_validation_sanitization.md)
- [REQ_SEC_003: Plugin Descriptor Validation](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_003_plugin_descriptor_validation.md)

## Assessment Methodology

1. **Static analysis**: Manual review of `cmd_tree()` in `doc.doc.sh` (lines 471–661), focusing on all paths where `$plugin_name`, `$inputs`, `$outputs`, and `$other_plugin` values are used.
2. **Data flow analysis**: Traced the origin of all values consumed in the dependency derivation logic — from `jq` parsing of `descriptor.json` files through comparison and string operations.
3. **Adversarial consideration**: Evaluated whether a crafted `descriptor.json` (or plugin directory name) could cause unexpected shell behavior.

## Findings

No exploitable security issues were identified. The following observations were made:

| # | Severity | Location | Description | Evidence | Remediation |
|---|----------|----------|-------------|----------|-------------|
| 1 | INFO | `doc.doc.sh:529` | `grep -q " $other_plugin "` uses unquoted `$other_plugin` as a regex pattern. Plugin names containing grep metacharacters (`.`, `*`, `[`) could theoretically cause unintended matches. | Plugin names are discovered from filesystem directory names under `$PLUGIN_DIR` (repository-controlled, not user input). No user-facing injection vector exists. | Accepted: use `grep -qF " $other_plugin "` (fixed-string) for defense in depth if plugin-name validation is ever relaxed. |

### Positive Security Observations

| # | Area | Observation |
|---|------|-------------|
| P1 | **jq-only JSON parsing** | All descriptor.json values are extracted with `jq -r '... \| keys[]'`. No `eval` or command substitution on extracted values. |
| P2 | **Read-only operations** | `cmd_tree()` reads descriptor files and performs string comparisons. No file writes, command execution, or network access. |
| P3 | **Controlled data sources** | `$inputs`, `$outputs`, and `$other_plugin` all originate from repository filesystem (plugin directory names and `descriptor.json` field names). No user-controlled input reaches these variables. |
| P4 | **Safe string comparisons** | Dependency matching uses `[ "$input_param" = "$out_param" ]` — quoted equality, not eval or glob expansion. |
| P5 | **Removal of trusted-input field** | Removing the `"dependencies"` field from `descriptor.json` eliminates a static, trust-required data field in favor of a deterministic, machine-derived approach. This reduces the attack surface for future descriptor tampering. |

## Threat Model

### Threat Context

`cmd_tree` is a display-only command that reads plugin descriptors and computes a dependency graph for terminal output. The threat surface is limited to:

1. **Malicious descriptor.json content**: A plugin with a crafted `descriptor.json` could affect the dependency graph display. However, this requires write access to the plugin directory, and no code is executed from descriptor values.
2. **Malicious plugin directory names**: Plugin directory names are used as identifiers and in `grep` patterns. Characters meaningful in basic regex (`.`, `*`, `[`) could cause false positive matches in the grep-based deduplication at line 529.

### Risk Assessment

Both threat scenarios require filesystem write access to the plugin directory and result in incorrect terminal output at worst — they do not enable code execution, privilege escalation, or data exfiltration.

**Residual Risk**: NEGLIGIBLE

## Recommendations

1. **Optional hardening (INFO)**: Replace `grep -q " $other_plugin "` (line 529) with `grep -qF " $other_plugin "` to use fixed-string matching, eliminating any regex metacharacter sensitivity in plugin names.

## Conclusion

**Overall Assessment: No Issues Found**

BUG_0005 removes the explicit `"dependencies"` field from `descriptor.json` and replaces it with a deterministic derivation algorithm based on output→input parameter name matching. The implementation is read-only, uses `jq` for all JSON parsing, performs no command execution on extracted values, and operates entirely on repository-controlled data. No security issues were identified.

---

**Document Control:**
- **Created:** 2026-03-10
- **Author:** security.agent
- **Status:** Complete
