# Security Review: FEATURE_0048 — WC Word Count Plugin

- **Report ID:** SECREV_029
- **Work Item:** FEATURE_0048
- **Date:** 2026-03-20
- **Agent:** security.agent
- **Status:** Approved

## Scope

Security review of the `wc` plugin implementation.

| File | Review Focus |
|------|-------------|
| `doc.doc.md/plugins/wc/main.sh` | Input validation, stdin handling, external command invocation |
| `doc.doc.md/plugins/wc/install.sh` | Minimal attack surface |
| `doc.doc.md/plugins/wc/installed.sh` | Minimal attack surface |

## Assessment

| Finding | Severity | Status |
|---------|----------|--------|
| All reviewed areas | — | No significant finding |

## Analysis

### 1. Text Handling (REQ_SEC_005)

Text is passed to `wc` exclusively via stdin using `printf '%s'` — no file paths are passed to `wc` and no shell interpolation of document content occurs. This is the safest possible approach.

### 2. Stdin Size Limiting (REQ_SEC_009)

`plugin_input.sh` is sourced, which enforces a 1MB stdin limit via `head -c 1048576`. This prevents memory exhaustion from oversized inputs.

### 3. No Filesystem Access

After reading JSON input, the plugin performs no filesystem operations. It extracts text from the JSON, counts it, and outputs results. The plugin is purely a stateless text processor.

### 4. JSON Output Safety

Output is constructed via `jq -n` with `--argjson` for numeric values. No string interpolation of user-controlled data in the output path.

## Verdict

**Approved** — Minimal attack surface. Text passed via stdin only. No filesystem access after input reading.
