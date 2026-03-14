# Security Review: FEATURE_0044 — run command -d / -o flag support

- **Report ID:** SECREV_022
- **Work Item:** FEATURE_0044
- **Date:** 2026-03-14
- **Agent:** security.agent
- **Status:** Approved

## Scope

Security review of the `-d` and `-o` flag handling and automatic `pluginStorage` derivation in the `run` command.

## Changes Reviewed

| File | Change |
|------|--------|
| `doc.doc.md/components/plugin_management.sh` | `-d`/`-o` parsing, `readlink -f` canonicalization, prefix validation, `mkdir -p` |

## Assessment

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| — | — | No issues found | — |

## Analysis

### 1. Output directory canonicalization (REQ_SEC_005)
- `-o <dir>` is canonicalized via `readlink -f` before constructing the `pluginStorage` path.
- The derived path `$canonical_out/.doc.doc.md/$plugin_name` is validated with a prefix check: `${derived_storage#"$canonical_out/"}` ensures it remains under the output directory.
- `plugin_name` has already been validated by `_validate_plugin_dir` (no `/`, `..`, etc.).

### 2. Input directory validation
- `-d <dir>` is validated for existence (`-d`) and readability (`-r`) before use.
- The path is passed to the plugin as `inputDirectory` via `jq --arg` — no shell injection possible.

### 3. Directory creation
- `mkdir -p "$derived_storage"` is safe: `derived_storage` is constructed from canonicalized paths and validated plugin name.

### 4. JSON injection prevention
- All new fields (`inputDirectory`, `pluginStorage`) are passed via `jq --arg`, consistent with existing fields.

### 5. Warning on conflict
- When both `-o` and `--plugin-storage` provided, `-o` takes precedence and a warning is emitted to stderr. The `--plugin-storage` value is discarded. No security impact.

## Positive Observations

1. ✅ Consistent with `plugin_execution.sh` canonicalization pattern
2. ✅ Prefix check prevents traversal outside output directory
3. ✅ All values passed through `jq --arg` — no interpolation
4. ✅ Input directory validated before use

## Verdict

**Approved** — The implementation follows security best practices and REQ_SEC_005 requirements.
