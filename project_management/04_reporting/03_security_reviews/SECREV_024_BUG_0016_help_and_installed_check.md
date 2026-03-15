# Security Review: BUG_0016 — Help text CLI flags & installed check

- **Report ID:** SECREV_024
- **Work Item:** BUG_0016
- **Date:** 2026-03-15
- **Agent:** security.agent
- **Status:** Approved

## Scope

Security review of:
1. The `usage` block rendering in `_run_command_help()` in `plugin_management.sh`
2. The `crm -e 'learn/unlearn ...'` invocations replacing `csslearn`/`cssunlearn` in `learn.sh`, `unlearn.sh`, and `train.sh`
3. The simplified `installed.sh` check

## Changes Reviewed

| File | Change |
|------|--------|
| `doc.doc.md/components/plugin_management.sh` | `_run_command_help()` reads `usage` array from descriptor.json via `jq -r` |
| `doc.doc.md/plugins/crm114/descriptor.json` | Added `usage` array with static flag/description entries |
| `doc.doc.md/plugins/crm114/learn.sh` | Replaced `csslearn "$CSS_FILE"` with `crm '-{ learn <osb unique microgroom> ( '"$CSS_FILE"' ) }'` |
| `doc.doc.md/plugins/crm114/unlearn.sh` | Replaced `cssunlearn "$CSS_FILE"` with `crm '-{ unlearn <osb unique microgroom> ( '"$CSS_FILE"' ) }'` |
| `doc.doc.md/plugins/crm114/train.sh` | Same replacement pattern as learn.sh/unlearn.sh |
| `doc.doc.md/plugins/crm114/installed.sh` | Changed from `crm || cssutil` to `crm` only |

## Assessment

| Finding | Severity | Status |
|---------|----------|--------|
| None | — | — |

## Analysis

1. **Usage block source:** The `"usage"` array is read from the plugin's local `descriptor.json` file using `jq -r`, not from user input. The descriptor file is already validated earlier in `cmd_run()` (existence + valid JSON). This is a trusted source.

2. **CRM114 command construction:** The `crm -e` invocations construct the CRM114 program text with the `$CSS_FILE` path embedded. This path has already been:
   - Constructed from a sanitized category name (`^[a-zA-Z0-9._-]+$` regex validation)
   - Canonicalized via `readlink -f`
   - Verified to be within `CANONICAL_STORAGE` (path traversal prevention)
   
   The `CSS_FILE` variable contains a safe, canonical path that cannot include shell metacharacters due to the category name sanitization. The CRM114 expression `'-{ learn <osb unique microgroom> ( '"$CSS_FILE"' ) }'` uses shell quoting correctly to embed the path.

3. **No new input vectors:** The `usage` array is read-only from descriptor.json. Users cannot control what flags are shown — this is determined by the plugin author.

4. **Installed check simplification:** Changing from `crm || cssutil` to `crm` only makes the check more conservative — it requires the primary binary rather than accepting a partial installation.

5. **stdin handling unchanged:** The data flow for learn/unlearn operations is identical: `echo "$file_text" | crm ...` instead of `echo "$file_text" | csslearn ...`. The text content piped to the command is the same validated file content.

## Verdict

**Approved** — No security concerns. All values used in CRM114 command construction have been validated through existing security gates. The `$CSS_FILE` path is sanitized via category name validation and canonical path resolution.
