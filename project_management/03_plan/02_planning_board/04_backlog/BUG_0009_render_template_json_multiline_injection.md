# render_template_json Multiline Value Injection Violates REQ_SEC_004

- **ID:** BUG_0009
- **Priority:** Medium
- **Type:** Bug
- **Created at:** 2026-03-10
- **Created by:** security.agent
- **Status:** BACKLOG
- **Assigned to:** developer.agent

## TOC

1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Dependencies](#dependencies)
4. [Related Links](#related-links)

## Overview

`render_template_json()` in `doc.doc.sh` extracts JSON key-value pairs using:

```bash
while IFS= read -r line; do
  local key="${line%%=*}"
  local val="${line#*=}"
  [ -n "$key" ] || continue
  content="${content//\{\{${key}\}\}/${val}}"
done < <(echo "$result_json" | jq -r 'to_entries[] | "\(.key)=\(.value)"')
```

`jq -r` decodes JSON string escape sequences, including `\n` → literal newline. When a plugin output value (such as `documentText` from the markitdown plugin or `ocrText` from ocrmypdf) contains embedded newlines, the `while IFS= read -r line` loop processes each line of that value as if it were a new `key=value` pair.

### Security Impact

If a processed document's text content begins with a line matching the format `<fieldName>=<value>`, that line is treated as a template substitution directive for `{{<fieldName>}}`. For example:

- A document whose first line is `filePath=/attacker-controlled` causes `{{filePath}}` in the template to be substituted with `/attacker-controlled` instead of the actual file path.
- A document whose first line is `mimeType=application/x-malicious` overrides the `{{mimeType}}` placeholder.

This violates:
- **REQ_SEC_004 Rule 2**: "No Nested Substitution — Variables substituted in single pass" (document content controls substitution of other variables)
- **REQ_SEC_004 Rule 4**: "No user-controlled variable names — only predefined set" (lines from document content become effective variable names)
- **REQ_SEC_004 Rule 5**: "Read-Only Variables — values from plugins/system, not user input" (document content overrides system-derived values)

### Note on Relationship to DEBTR_003

[DEBTR_003](DEBTR_003_render_template_json_multiline_values.md) tracks the functional manifestation: multiline values are truncated to their first line. This bug tracks the distinct security consequence: continuation lines of a multiline value are interpreted as new key=value substitution commands, violating REQ_SEC_004. Both issues share the same root cause and the same fix.

**Affected file:** `doc.doc.sh` — `render_template_json()`, lines 889–894

### Fix

Replace the `jq -r 'to_entries[] | "\(.key)=\(.value)"'` line-by-line approach with per-key extraction that preserves multiline values without splitting:

```bash
render_template_json() {
  local template="$1"
  local result_json="$2"
  local content
  content="$(cat "$template")"

  # Iterate over keys; extract each value preserving all lines (fixes DEBTR_003 and BUG_0009)
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    local val
    val="$(echo "$result_json" | jq -r --arg k "$key" '.[$k] // empty')"
    content="${content//\{\{${key}\}\}/${val}}"
  done < <(echo "$result_json" | jq -r 'keys[]')

  # Derive fileName from filePath
  local fp
  fp=$(echo "$result_json" | jq -r '.filePath // empty')
  if [ -n "$fp" ]; then
    local fname
    fname="$(basename "$fp")"
    content="${content//\{\{fileName\}\}/${fname}}"
  fi

  printf '%s' "$content"
}
```

This approach:
1. Iterates over JSON keys only — document content never becomes a key name.
2. Extracts the full value (including all lines) for each key via a separate `jq -r` call.
3. Preserves bash parameter expansion for substitution — no `eval`, no code execution risk.

## Acceptance Criteria

- [ ] A document whose first line is `filePath=/evil` does NOT cause `{{filePath}}` in the template to be substituted with `/evil`
- [ ] `{{documentText}}` is substituted with the full multiline markitdown output (resolves DEBTR_003)
- [ ] `{{ocrText}}` is substituted with the full multiline OCR output (resolves DEBTR_003)
- [ ] Single-line placeholder substitutions continue to work correctly (regression)
- [ ] Template variables with no matching JSON key are left unchanged (or substituted with empty string per current behavior)
- [ ] No shell injection is possible through multiline values (bash parameter expansion remains the substitution mechanism; no `eval`)
- [ ] ShellCheck passes on the modified function

## Dependencies

- Resolves [DEBTR_003](DEBTR_003_render_template_json_multiline_values.md) as a side effect of the fix.

## Related Links

- Security Review: [SECREV_008](../../../04_reporting/03_security_reviews/SECREV_008_FEATURE_0019_process_output_directory.md)
- Technical Debt: [DEBTR_003](DEBTR_003_render_template_json_multiline_values.md) — same root cause, functional manifestation
- Security Requirement: [REQ_SEC_004](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_004_template_injection_prevention.md) — template injection prevention
- Feature: [FEATURE_0019](../06_done/FEATURE_0019_process_output_directory.md)
