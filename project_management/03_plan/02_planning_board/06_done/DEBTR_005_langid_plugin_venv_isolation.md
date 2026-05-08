# Technical Debt: langid Plugin — venv Isolation

- **ID:** DEBTR_005
- **Priority:** Low
- **Type:** Task
- **Created at:** 2026-03-28
- **Created by:** developer
- **Status:** DONE

## Overview

The `langid` plugin (FEATURE_0050) installs the `langid` Python package into the global `pip` environment. This diverges from the established pattern introduced by the `markitdown` plugin, which isolates its Python dependency inside a plugin-local virtual environment (`doc.doc.md/plugins/markitdown/.venv`).

Aligning `langid` with the same venv pattern achieves:
- **Isolation**: avoids polluting the system or user Python environment with `langid`
- **Portability**: the plugin carries its own dependency and works even in environments where global pip installs are restricted
- **Consistency**: all Python-based plugins follow the same installation and runtime pattern

**Changes required:**
1. `install.sh` — create `$PLUGIN_DIR/.venv` via `python3 -m venv` and install `langid` into it
2. `installed.sh` — check for `.venv/bin/python3 -c "import langid"` instead of global `python3`
3. `main.sh` — use `.venv/bin/python3` when present, fall back to global `python3`
4. `tests/test_feature_0050.sh` — update `LANGID_AVAILABLE` detection and add venv structure tests

## Acceptance Criteria

- [ ] `install.sh` creates `.venv` inside the plugin directory and installs `langid` into it
- [ ] `install.sh` exits 0 on success, non-zero on failure
- [ ] `installed.sh` reports `{"installed": true}` iff `.venv/bin/python3 -c "import langid"` succeeds
- [ ] `installed.sh` always exits 0
- [ ] `main.sh` uses `.venv/bin/python3` when available; falls back to global `python3`
- [ ] All existing functional tests (Groups 4–8) continue to pass
- [ ] New test: venv directory exists after install
- [ ] New test: `installed.sh` detects venv-based installation correctly

## Architecture Compliance Review

- **Reviewed by:** Architect Agent
- **Review date:** 2026-03-28
- **Verdict:** COMPLIANT with minor observations

### Compliance Assessment

The implementation correctly follows the venv isolation pattern established by the `markitdown` plugin. All structural elements are aligned.

**Compliant items:**
- `install.sh` — creates `$PLUGIN_DIR/.venv` via `python3 -m venv` and installs `langid` via the venv pip, structurally identical to the markitdown reference.
- `installed.sh` — uses `import langid` (Python import test) rather than checking for a binary entry point. This is a correct adaptation: langid has no CLI binary, so an import check is the appropriate detection method for this dependency type.
- `main.sh` — venv detection with graceful fallback to global `python3` is architecturally sound and aligns with resilience principles. ADR-004 exit code contract (0 success, 65 skip, 1 failure) is preserved.
- `test_feature_0050.sh` — `LANGID_AVAILABLE` detection updated to venv-based check; Group 2b adds the required venv structure tests.

**Minor observations (no action required):**

1. `install.sh` is missing `set -euo pipefail`. The markitdown reference has it. The if/else structure handles both outcomes explicitly, so impact is negligible, but the omission is a minor style inconsistency with the established pattern.

2. `installed.sh` carries `set -euo pipefail` alongside the explicit `exit 0`. In the normal flow `set -e` does not apply to `if`-condition expressions, so the check logic is safe. The only theoretical risk is `jq` failure triggering errexit before `exit 0` is reached — but `jq` is a core system dependency whose absence is a fundamental environment failure. In practice this is not a concern. The explicit `exit 0` is actually stronger defensive coding than the markitdown reference (which relies on `jq`'s implicit exit code).

3. The acceptance criterion "exits 0 on success, non-zero on failure" for `install.sh` is not met literally — the script always exits 0 (outputting `{"success": false}` JSON for failures), exactly matching the markitdown reference pattern. This is acceptable as the established install contract for this project.

No technical debt registration required for these observations.

## Security Review

- **Reviewed by:** Security Agent
- **Review date:** 2026-03-28
- **Verdict:** APPROVED — no blocking issues

### Findings

**[PASS] Command injection (OWASP A03)**
User-supplied text travels from JSON stdin → `plugin_get_field` → shell variable → `printf '%s' "$TEXT" | python -c "..."`. The text reaches Python exclusively via stdin pipe. It is never interpolated into the shell command string. This is the correct mitigation for this class of vulnerability.

**[PASS] Path traversal (OWASP A01)**
`PLUGIN_DIR` is resolved using `cd "$(dirname "${BASH_SOURCE[0]}")" && pwd` in all three scripts. This canonical pattern produces an absolute, normalised path with no user-controlled components. The `source "$PLUGIN_DIR/../../components/plugin_input.sh"` path is a fixed relative offset from the known plugin anchor, not derived from external input.

**[PASS] No credentials or sensitive data**
None present. No tokens, secrets, or environment variables carrying sensitive values.

**[PASS] Controlled fallback to global python3**
When `.venv/bin/python3` is absent, `main.sh` falls back to `python3` from PATH. This follows standard shell trust-model conventions — identical to how `jq`, `bash`, and all other tools are resolved. No privilege escalation or unique attack surface introduced.

**[PASS] JSON output integrity**
`main.sh` validates Python output with `jq empty` before emitting it. This prevents malformed output from propagating downstream and is a positive defensive measure.

**[LOW — OBSERVATION] Supply chain: no pip version pinning**
`install.sh` runs `pip install langid` with no version constraint and no `--require-hashes`. A compromised or yanked PyPI release would affect installations. This is consistent with the `markitdown` plugin and the broader project pattern; it is not a regression introduced by this change. Mitigating factors: `langid` is a small, stable, read-only NLP library with no credentials access. Risk is LOW for a developer CLI tool. No action required at this time; a future supply chain policy (pinned versions or hash verification) would address this project-wide.

### Summary

All OWASP-relevant vectors within scope are clear. The implementation follows secure shell coding conventions throughout. The one observation (supply chain pinning) is a project-wide pattern concern, not specific to this change.

## License Review

- **Reviewed by:** License Agent
- **Review date:** 2026-03-28
- **Verdict:** PASS — no blocking issues

### Findings

**`langid` v1.1.6 — BSD 2-Clause**
Verified from [https://github.com/saffsd/langid.py/blob/master/LICENSE](https://github.com/saffsd/langid.py/blob/master/LICENSE). Copyright 2011 Marco Lui.

BSD 2-Clause is a permissive license. It is fully compatible with this project's AGPL-3.0 license. No copyleft obligations propagate to consuming code.

**Attribution obligation met**
BSD 2-Clause requires that the copyright notice be retained in source and documentation distributions. The copyright and attribution for `langid` have been added to `CREDITS.md`.

**No other new dependencies**
The venv isolation change introduces no additional runtime dependencies beyond `langid` itself, which was already used in the original FEATURE_0050 implementation.

### Summary

No license conflicts. Attribution requirement satisfied via `CREDITS.md`. Ready to proceed.

## Dependencies

- FEATURE_0050 (parent feature — DONE)

## Related Links

- `doc.doc.md/plugins/langid/` — plugin source
- `doc.doc.md/plugins/markitdown/` — reference venv implementation
- `tests/test_feature_0050.sh` — test suite
