# render_template_json Truncates Multiline Plugin Output Values

- **ID:** DEBTR_003
- **Status:** DONE
- **Created at:** 2026-03-06
- **Created by:** architect.agent
- **Priority:** Medium

## TOC

1. [Deviation Summary](#deviation-summary)
2. [Context](#context)
3. [Impact](#impact)
4. [Related Documents](#related-documents)
5. [Remediation Plan](#remediation-plan)
6. [Resolution](#resolution)

## Deviation Summary

`render_template_json` in `doc.doc.sh` uses a line-by-line `while read` loop to parse `jq -r` key=value output, silently discarding all lines after the first for any plugin output value that contains embedded newlines.

## Context

FEATURE_0019 introduced `render_template_json()`, which substitutes `{{key}}` placeholders in a template with values from the merged plugin JSON result. The function extracts key-value pairs with:

```bash
while IFS= read -r line; do
  local key="${line%%=*}"
  local val="${line#*=}"
  [ -n "$key" ] || continue
  content="${content//\{\{${key}\}\}/${val}}"
done < <(echo "$result_json" | jq -r 'to_entries[] | "\(.key)=\(.value)"')
```

When a JSON string value contains embedded newlines, `jq -r` emits those newlines literally. The `while read -r line` loop processes each line separately:
- Line 1 (`key=first_line`) is correctly parsed; the placeholder is substituted with the first line only.
- Lines 2–N (continuation of the value) have no `=` in the expected position relative to the key, so `key` evaluates to the full line text and is silently filtered by `[ -n "$key" ] || continue`.

The result is that `{{documentText}}` (markitdown plugin) and `{{ocrText}}` (ocrmypdf plugin) — both of which produce multiline markdown content — will only be substituted with their first line when referenced in a template.

ARC-0002 (Template Processing Concept) does not restrict variable values to single lines. The architecture assumes the substitution mechanism handles arbitrary string values correctly.

## Impact

- **Correctness**: Any template referencing `{{documentText}}` or `{{ocrText}}` will produce a sidecar file containing only the first line of the extracted content. This is silent data loss — no error is emitted.
- **Primary use case affected**: The markitdown plugin (FEATURE_0017) was built specifically to populate `{{documentText}}` in templates. This defect renders that integration non-functional for multi-line documents.
- **Current state**: The default template (`default.md`) only references single-line stat metadata fields, so no existing output is affected today. The defect becomes visible as soon as a user adds `{{documentText}}` or `{{ocrText}}` to a template.
- **Future plugins**: Any plugin that produces richtext, extracted content, or multi-paragraph summaries will exhibit the same truncation.

## Related Documents

- **Architecture Review:** [ARCHREV_008](../../../04_reporting/01_architecture_reviews/ARCHREV_008_FEATURE_0019_process_output_directory.md) — DEV-001
- **Architecture Concept:** [ARC-0002: Template Processing](../../../02_project_vision/03_architecture_vision/08_concepts/ARC_0002_template_processing.md)
- **Work Item:** [FEATURE_0019](../06_done/FEATURE_0019_process_output_directory.md)
- **Work Item:** [FEATURE_0017](../06_done/FEATURE_0017_markitdown_ms_office_plugin.md) — markitdown plugin produces multiline `documentText`

## Remediation Plan

Replace the line-by-line `while read` parsing in `render_template_json` with a null-safe approach that correctly handles multiline values. Recommended approach: iterate over keys using `jq -r 'keys[]'` and extract each value with a separate `jq -r --arg key "$k" '.[$key] // empty'` call, ensuring the substitution value is the full multi-line string. Alternative: use `jq` to build a lookup of `key\x00value` pairs separated by null bytes and read with `IFS= read -r -d ''`.

Example corrected implementation outline:

```bash
render_template_json() {
  local template="$1"
  local result_json="$2"
  local content
  content="$(cat "$template")"

  # Iterate over each key; extract value preserving all lines
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

Acceptance criteria for remediation:
- [x] `render_template_json` correctly substitutes `{{documentText}}` with the full multiline markitdown output
- [x] `render_template_json` correctly substitutes `{{ocrText}}` with the full multiline OCR output
- [x] Single-line placeholder substitutions continue to work correctly (regression)
- [x] No shell injection is possible through multiline values (bash parameter expansion remains the substitution mechanism; no `eval`)
- [x] Existing tests continue to pass

## Resolution

Resolved as part of BUG_0009 fix. The `render_template_json()` function was rewritten to use per-key extraction via `jq -r 'keys[]'` and individual value extraction via `jq -r --arg k "$key" '.[$k] // empty'`. This preserves multiline values correctly. All acceptance criteria verified by tests in `tests/test_bug_0009.sh`.
