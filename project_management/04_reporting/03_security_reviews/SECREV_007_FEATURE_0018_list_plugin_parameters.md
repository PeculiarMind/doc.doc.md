# Security Review: FEATURE_0018 — List Plugin Parameters

- **ID:** SECREV_007
- **Created at:** 2026-03-10
- **Created by:** security.agent
- **Work Item:** [FEATURE_0018](../../03_plan/02_planning_board/06_done/FEATURE_0018_list_plugin_parameters.md)
- **Status:** Issues Found

## TOC

1. [Reviewed Scope](#reviewed-scope)
2. [Security Concept Reference](#security-concept-reference)
3. [Assessment Methodology](#assessment-methodology)
4. [Findings](#findings)
5. [Threat Model](#threat-model)
6. [Recommendations](#recommendations)
7. [Conclusion](#conclusion)

## Reviewed Scope

| File / Function | Change | Purpose |
|-----------------|--------|---------|
| `doc.doc.sh` — `cmd_list()` | Extended | Added `list parameters` (all plugins) and `list --plugin <name> --parameters` (single plugin) sub-commands |

Specifically reviewed lines covering:
- `list parameters` branch (lines 722–755): enumerates all plugin descriptors
- `list --plugin <name> --parameters` branch (lines 831–870): resolves single plugin descriptor by name

## Security Concept Reference

- [Security Concept — Scope 3: Plugin System Architecture](../../02_project_vision/04_security_concept/01_security_concept.md)
- [REQ_SEC_001: Input Validation and Sanitization](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_001_input_validation_sanitization.md)
- [REQ_SEC_005: Path Traversal Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md)
- [REQ_SEC_006: Error Information Disclosure Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_006_error_information_disclosure_prevention.md)
- Security Controls: SC-001

## Assessment Methodology

1. **Static analysis**: Full review of the `cmd_list()` function additions related to FEATURE_0018.
2. **Data flow tracing**: Traced the `--plugin <name>` argument from CLI input through path construction and file access.
3. **Path traversal testing**: Evaluated whether `$plugin_name` with `../` sequences can escape `$PLUGIN_DIR`.
4. **Read-only impact analysis**: Confirmed the scope of accessible files if path traversal succeeds.

## Findings

| # | Severity | Location | Description | Evidence | Remediation | Bug |
|---|----------|----------|-------------|----------|-------------|-----|
| 1 | MEDIUM | `doc.doc.sh:832–833` | **Path traversal via `--plugin <name>` argument.** `plugin_dir="$PLUGIN_DIR/$plugin_name"` constructs a path directly from user input without sanitization or canonicalization. Passing `--plugin ../../../../some/path` resolves to a directory outside `$PLUGIN_DIR`. If that directory exists and contains a file named `descriptor.json`, `jq` will read and display its contents as if it were a plugin descriptor. | `./doc.doc.sh list --plugin '../../../../tmp' --parameters` → resolves `plugin_dir` to a path outside the plugin directory; if `/tmp/descriptor.json` exists and is valid JSON, its contents are displayed via `jq`. Directory existence check (`[ ! -d "$plugin_dir" ]`) does not reject traversal since the traversed path may be a valid directory. | Add canonicalization and boundary enforcement: resolve `plugin_dir` with `readlink -f` and reject if it does not start with `"$PLUGIN_DIR/"`. | [BUG_0007](../../03_plan/02_planning_board/04_backlog/BUG_0007_list_plugin_path_traversal.md) |
| 2 | LOW | `doc.doc.sh:810`, `836` | **Error messages disclose `$PLUGIN_DIR` absolute path.** When a plugin is not found, the error message includes the full `$PLUGIN_DIR` path: `"Error: Plugin 'name' not found in /absolute/path/to/plugins"`. This reveals the installation directory structure. | `./doc.doc.sh list --plugin nonexistent --parameters` → `Error: Plugin 'nonexistent' not found in /home/runner/work/.../plugins`. | Show only the plugin name in the error message; omit the full directory path. Per REQ_SEC_006, internal paths should not appear in production error messages. | No bug created — LOW severity; acceptable for a developer-facing CLI tool. |

### Positive Security Observations

| # | Area | Observation |
|---|------|-------------|
| P1 | **Read-only operations** | Both `list parameters` branches exclusively read `descriptor.json` files and produce tabular terminal output. No writes, no command execution, no network access. |
| P2 | **jq-based JSON processing** | All descriptor parsing uses `jq` with fixed expressions. No user-controlled data is passed to `jq` expressions or shell commands. |
| P3 | **JSON validity pre-check** | `jq empty "$descriptor" 2>/dev/null` validates JSON before processing. Malformed JSON causes a clean error exit. |
| P4 | **No descriptor field execution** | Descriptor values are displayed as table output via `jq @tsv` and `column`. No descriptor field value is executed or interpolated into a shell command. |
| P5 | **`list parameters` (all plugins) is safe** | Uses `discover_all_plugins "$PLUGIN_DIR"` which enumerates only the controlled plugin directory. No user-supplied plugin name is involved. |

## Threat Model

### Threat Context

`list --plugin <name>` is a display command. The user-supplied plugin name is the sole attack surface. The threat scenario is:

1. **Path traversal via `--plugin`**: Attacker passes `../` sequences to read a `descriptor.json` file at an arbitrary location. Impact is limited to information disclosure of the file's JSON contents.

### Impact Scope

The traversal enables reading only files named `descriptor.json` that are valid JSON. This limits the exploitable attack surface significantly. No code is executed from the file's contents.

However, if a sensitive JSON file happens to be named `descriptor.json` somewhere accessible via the traversal, its contents would be displayed on the terminal. Additionally, a crafted `descriptor.json` in an attacker-controlled directory could produce misleading output (e.g., fake parameter tables), but this has no security impact beyond user confusion.

### Residual Risks

| Risk | Severity | Status |
|------|----------|--------|
| Arbitrary `descriptor.json` read via `--plugin` traversal | MEDIUM | **Open** — BUG_0007 filed |
| Internal path disclosure in error messages | LOW | **Accepted** — developer CLI context |

## Recommendations

### Immediate (before FEATURE_0018 considered fully secure)

1. **Fix BUG_0007**: Canonicalize `plugin_dir` with `readlink -f` and validate it starts with `"$PLUGIN_DIR/"` before checking for the directory. This prevents `../` traversal from escaping the plugin directory. Apply the fix symmetrically to both the `--commands` branch (line 805) and the `--parameters` branch (line 832).

   Example fix:
   ```bash
   local plugin_dir="$PLUGIN_DIR/$plugin_name"
   local canonical_plugin_dir
   canonical_plugin_dir="$(readlink -f "$plugin_dir" 2>/dev/null || echo "")"
   if [ -z "$canonical_plugin_dir" ] || [[ "$canonical_plugin_dir" != "$PLUGIN_DIR/"* ]]; then
     echo "Error: Plugin '$plugin_name' not found" >&2
     exit 1
   fi
   ```

### Optional Hardening

2. **Sanitize error messages** (LOW): Remove `$PLUGIN_DIR` from error messages. Show only the plugin name per REQ_SEC_006.

## Conclusion

**Overall Assessment: Issues Found**

The FEATURE_0018 implementation is read-only and uses `jq` safely for all descriptor processing. No command injection or privilege escalation risks exist. However, the `--plugin <name>` argument is accepted without canonicalization or boundary enforcement, enabling path traversal to read arbitrary files named `descriptor.json` outside the plugin directory. This violates REQ_SEC_005 (Path Traversal Prevention) and REQ_SEC_001 (Input Validation).

**Bug work item BUG_0007 has been created in the backlog** and assigned to developer.agent for remediation.

---

**Document Control:**
- **Created:** 2026-03-10
- **Author:** security.agent
- **Status:** Complete
- **Next Review:** After BUG_0007 remediation
