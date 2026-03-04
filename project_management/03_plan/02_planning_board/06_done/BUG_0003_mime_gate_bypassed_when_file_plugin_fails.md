# MIME Filter Gate Bypassed When `file` Plugin Fails at Runtime

- **ID:** BUG_0003
- **Priority:** Low
- **Type:** Bug
- **Created at:** 2026-03-03
- **Created by:** security.agent
- **Status:** Done
- **Assigned to:** developer.agent
- **Fixed in:** FEATURE_0007 implementation cycle

## TOC

## Overview

In `doc.doc.sh` `process_file()`, the MIME filter gate (REQ_SEC_002) is placed inside the `if … then` success branch of `run_plugin`. When `run_plugin "file"` exits non-zero (i.e., the `file` plugin fails at runtime), the `else` branch executes `continue`, which skips to the next loop iteration before the `if [ "$plugin_name" = "file" ]` gate block is ever reached. The file therefore bypasses MIME filtering entirely and continues through all subsequent plugins, appearing in output even if active `--include` / `--exclude` MIME criteria would otherwise exclude it.

This violates **REQ_SEC_002** (Filter Logic Correctness): "MIME type filter must be covered by tests verifying include/exclude correctness — edge cases: wildcard MIME types, unknown MIME type fallback."

**Discovered in:** [Security Assessment — FEATURE_0007](../05_implementing/FEATURE_0007_file_plugin_first_in_chain_and_mime_filter_gate.md#security-assessment)  
**Affects:** `doc.doc.sh` `process_file()` — FEATURE_0007 implementation

### Root Cause

```bash
# doc.doc.sh — process_file() (simplified)
for plugin_name in "${plugins[@]}"; do
  if plugin_output=$(run_plugin "$plugin_name" ...); then
    combined_result=$(...)
  else
    continue   # <-- jumps to next iteration; gate below is never reached
  fi

  if [ "$plugin_name" = "file" ]; then
    # MIME filter gate — unreachable when run_plugin "file" fails
    ...
  fi
done
```

### Reproduction

```bash
# 1. Temporarily make the file plugin script non-executable
chmod -x doc.doc.md/plugins/file/main.sh

# 2. Run with a MIME include filter that should exclude .sh files (text/x-shellscript)
./doc.doc.sh process -d . -i "application/pdf"

# Expected: no output (no PDFs in .)
# Actual:   files are emitted because the file plugin fails and the gate is skipped
```

### Impact

- MIME include/exclude criteria are silently unenforced when the `file` plugin encounters a runtime error (e.g., `file` binary missing, plugin script permissions changed, unexpected exit from inside `main.sh`).
- The `file` plugin's `run_plugin` pre-checks (script exists, is executable) reduce the likelihood, but runtime failures inside the script itself (e.g., `set -euo pipefail` triggering on an unexpected error) are possible.
- Severity is **Low**: the bypass window is narrow and requires a `file` plugin failure that would itself be observable as a warning in stderr output.

## Acceptance Criteria

- [ ] When `run_plugin "file"` fails for a given file and MIME criteria are active, the file is **skipped** (not emitted to output) rather than passed through
- [ ] The fix does not change behaviour when no MIME criteria are active (backward compatibility preserved)
- [ ] Existing tests in `test_feature_0007.sh`, `test_doc_doc.sh`, and `test_plugins.sh` continue to pass
- [ ] A new test covers the bypass scenario: `file` plugin failure with active MIME include filter → file must not appear in output

## Suggested Fix

**Option A — Treat `file` plugin failure as a hard skip for that file:**  
If `run_plugin "file"` fails and MIME criteria are active, return early (skip the file) rather than continuing with partial results. This matches the intent: without a valid MIME type, the filter gate cannot be evaluated correctly.

```bash
if plugin_output=$(run_plugin "$plugin_name" "$file_path" "$PLUGIN_DIR"); then
  combined_result=$(echo "$combined_result" "$plugin_output" | jq -s '.[0] * .[1]')
else
  # If the file plugin fails and MIME criteria are active, skip the file (cannot evaluate gate)
  if [ "$plugin_name" = "file" ]; then
    local _has_mime_criteria=false
    [ ${#_MIME_INCLUDE_ARGS[@]} -gt 0 ] && _has_mime_criteria=true
    [ ${#_MIME_EXCLUDE_ARGS[@]} -gt 0 ] && _has_mime_criteria=true
    [ "$_has_mime_criteria" = true ] && return 0
  fi
  continue
fi
```

**Option B — Move gate check to cover both success and failure paths:**  
After the if/else block, always check if `plugin_name = "file"` and if `mimeType` is absent/empty, treat it as a gate failure when MIME criteria are active.

## Dependencies

- **Blocks:** FEATURE_0007 promotion to DONE (security gate not fully enforced)
- **Related:** REQ_SEC_002, FEATURE_0007

## Related Links

- Feature: [FEATURE_0007](../05_implementing/FEATURE_0007_file_plugin_first_in_chain_and_mime_filter_gate.md)
- Security Assessment: [FEATURE_0007 — Security Assessment](../05_implementing/FEATURE_0007_file_plugin_first_in_chain_and_mime_filter_gate.md#security-assessment)
- Requirement: [REQ_SEC_002](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_002_filter_logic_correctness.md)
