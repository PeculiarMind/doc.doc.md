# Architecture Review: FEATURE_0046 — CRM114 Text Classification Plugin

- **Report ID:** ARCHREV_026
- **Work Item:** FEATURE_0046
- **Date:** 2026-03-18
- **Agent:** architect.agent
- **Status:** Compliant

## Scope

Review of the `crm114` plugin implementation spanning:

| File | Change |
|------|--------|
| `doc.doc.md/plugins/crm114/descriptor.json` | New plugin descriptor |
| `doc.doc.md/plugins/crm114/process.sh` | Pipeline classification command |
| `doc.doc.md/plugins/crm114/manageCategories.sh` | Interactive category setup |
| `doc.doc.md/plugins/crm114/train.sh` | Per-document interactive labeling |
| `doc.doc.md/plugins/crm114/learn.sh` | Non-interactive learn command |
| `doc.doc.md/plugins/crm114/unlearn.sh` | Non-interactive unlearn command |
| `doc.doc.md/plugins/crm114/listCategories.sh` | List trained categories |
| `doc.doc.md/plugins/crm114/install.sh` | Dependency installer |
| `doc.doc.md/plugins/crm114/installed.sh` | Availability check |
| `tests/test_feature_0046.sh` | TDD test suite |

## Changes Reviewed

### descriptor.json — ADR-003 Compliance

Follows the established JSON descriptor schema. All input field names use lowerCamelCase (`filePath`, `pluginStorage`, `textContent`, `ocrText`, `category`). Commands reference correct `.sh` script files. Interactive commands (`manageCategories`, `train`) are correctly marked with `"interactive": true`. Non-interactive commands do not set this flag.

**Structural pattern matches** stat and file plugins exactly.

### process.sh — ADR-004 Exit Code Contract

Exit code strategy matches the established contract:

- **Exit 65** (skip): missing/empty textContent, non-existent pluginStorage, no trained `.css` files. All are legitimate "skip" cases per ADR-004, not errors.
- **Exit 1** (error): missing `pluginStorage` field, path traversal detected.
- **Exit 0** (success): classification completed; returns `{"categories": [...]}` JSON.

The `plugin_input.sh` shared component is sourced for input reading and filePath validation — consistent with all other plugins.

### Storage Pattern — REQ_0029 Compliance

All `.css` model files are stored exclusively under the injected `pluginStorage` path. No plugin script constructs or derives storage paths independently. The `pluginStorage` field is read from JSON input (for non-interactive commands) or from positional args (for interactive `manageCategories`). This is compliant with REQ_0029.

The `learn.sh` creates the pluginStorage directory if it does not exist (`mkdir -p`), which is consistent with how other stateful plugins handle first-use initialization.

### Security — REQ_SEC_005 and REQ_SEC_009

- `pluginStorage` path traversal check (`*..* pattern`) is applied in every script before any file I/O: `process.sh`, `learn.sh`, `unlearn.sh`, `listCategories.sh`, `manageCategories.sh`, `train.sh`.
- Category name sanitization (`^[A-Za-z0-9._-]+$`) prevents path traversal through category names in `learn.sh` and `unlearn.sh`.
- `plugin_input.sh` enforces the 1MB stdin limit (REQ_SEC_009) via `head -c 1048576`.
- No shell variable interpolation into command arguments; text is passed via `printf '%s\n' "$TEXT" | csslearn "$CSS_FILE"` (stdin, not args), preventing injection.

### Interactive Commands — BUG_0015 Pattern

`manageCategories` and `train` are correctly declared `"interactive": true` in `descriptor.json`. This causes `cmd_run` to pass `pluginStorage` and `inputDirectory` as positional args and leave stdin free. `cmd_loop` always pipes JSON to stdin regardless of the flag, so `train.sh` correctly reads JSON from stdin and uses `/dev/tty` for interactive prompts.

### No Changes to Core Components

All changes are confined to the new `doc.doc.md/plugins/crm114/` directory and `tests/test_feature_0046.sh`. No modifications to `doc.doc.sh`, `plugin_execution.sh`, `plugin_management.sh`, or any other core component.

## Compliance Assessment

| Criterion | Status | Notes |
|-----------|--------|-------|
| ADR-004 exit code contract | ✅ Compliant | Exit 65 for skips; exit 1 for errors |
| ADR-003 JSON descriptor schema | ✅ Compliant | lowerCamelCase, correct structure |
| REQ_0029 plugin storage isolation | ✅ Compliant | All state in pluginStorage only |
| REQ_SEC_005 path traversal prevention | ✅ Compliant | Both pluginStorage and category name validated |
| REQ_SEC_009 stdin size limit | ✅ Compliant | Via plugin_input.sh |
| BUG_0015 interactive flag pattern | ✅ Compliant | interactive: true on manageCategories and train |
| Plugin boundary isolation | ✅ Compliant | No changes to core components |

## Recommendations

1. **crmclassify output parsing**: `process.sh` uses a regex to parse `crmclassify` output. The CRM114 output format may vary across versions. The current pattern `([^/[:space:]]+)\.css[[:space:]]*:?[[:space:]]*pR:[[:space:]]*([+-]?[0-9]+\.?[0-9]*)` is broadly compatible but should be tested against the actual CRM114 version in the deployment environment. This is acceptable risk for a first implementation.

2. **manageCategories positional args**: The feature spec mentions "Reads `pluginStorage` from JSON on stdin" but `cmd_run` with `interactive: true` passes positional args. The implementation correctly uses positional args ($1) which matches the `cmd_run` behavior for interactive commands. The spec text is stale but the implementation is correct.

No deviations requiring DEBTR or TASK items were identified.
