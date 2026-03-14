# Architecture Review: FEATURE_0040 Full Mustache Template Support via Python

- **ID:** ARCHREV_018
- **Created at:** 2026-03-14
- **Created by:** architect.agent
- **Work Item:** [FEATURE_0040: Full Mustache Template Support via Python](../../03_plan/02_planning_board/05_implementing/FEATURE_0040_full-mustache-template-support.md)
- **Status:** Compliant

## Table of Contents
1. [Reviewed Scope](#reviewed-scope)
2. [Architecture Vision Reference](#architecture-vision-reference)
3. [Compliance Assessment](#compliance-assessment)
4. [Deviations Found](#deviations-found)
5. [Recommendations](#recommendations)
6. [Conclusion](#conclusion)

## Reviewed Scope

| File | Change Purpose |
|------|---------------|
| `doc.doc.md/components/mustache_render.py` (new) | Standalone Python 3 Mustache renderer; accepts template file path and JSON string, renders via `chevron` library, writes result to stdout |
| `doc.doc.md/components/templates.sh` (updated) | `render_template_json` replaced Bash string-substitution loop with delegation to `mustache_render.py`; path resolved relative to `templates.sh` |
| `tests/test_feature_0040.sh` (new) | 40 tests covering variable substitution, sections, inverted sections, array loops, comments, fileName derivation, error handling, integration, backward compatibility, and eval/exec prohibition |

## Architecture Vision Reference

- **ADR-001:** [Mixed Bash/Python Implementation](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_001_mixed_bash_python_implementation.md) — rendering logic delegated from Bash to Python; Bash retains orchestration role via thin shim in `templates.sh`
- **ADR-003:** [JSON Plugin Descriptors](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md) — JSON I/O contract unchanged; `mustache_render.py` receives the same accumulated JSON object from the plugin pipeline
- **ADR-004:** [Plugin Exit Code Strategy](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md) — exit code contract (0 success / 1 error) preserved; `render_template_json` propagates exit codes from `mustache_render.py`
- **REQ_0007:** [Markdown Output](../../02_project_vision/02_requirements/03_accepted/REQ_0007_markdown-output.md) — template rendering is the final step in sidecar Markdown file generation
- **REQ_0009:** [Process Command](../../02_project_vision/02_requirements/03_accepted/REQ_0009_process-command.md) — `render_template_json` is invoked as part of the process pipeline
- **REQ_SEC_004:** [Template Injection Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_004_template_injection_prevention.md) — no `eval`/`exec` in template rendering; Mustache by design does not execute code

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| ADR-001: Mixed Bash/Python Implementation | ✅ Compliant | Rendering logic moved to Python (`mustache_render.py`); Bash orchestration preserved — `render_template_json` in `templates.sh` is a thin shim calling `python3`. This follows the established pattern used by `filter.py` and `plugin_info.py`. |
| ADR-003: JSON Plugin Descriptors / I/O | ✅ Compliant | `mustache_render.py` accepts the same JSON string produced by the plugin pipeline. No changes to JSON structure; existing keys render via Mustache `{{key}}` syntax identically to the prior Bash substitution. Array-valued keys are now natively iterable via `{{#key}}...{{/key}}`. |
| ADR-004: Plugin Exit Code Strategy | ✅ Compliant | `mustache_render.py` exits 0 on success and 1 on error. `render_template_json` propagates this exit code unchanged. No impact on plugin exit code handling. |
| REQ_0007: Markdown Output | ✅ Compliant | Rendered Markdown output is identical for all existing `{{key}}` placeholders. Full Mustache spec support (sections, loops, comments) unlocks richer template authoring for future templates. |
| REQ_0009: Process Command | ✅ Compliant | `render_template_json` function signature (two positional args: template file, JSON string) is unchanged. All callers in the process pipeline continue to work without modification. |
| REQ_SEC_004: Template Injection Prevention | ✅ Compliant | `mustache_render.py` contains no `eval()` or `exec()` calls. The `chevron` library treats all data values as plain strings — no code execution is possible via template content. Verified by test T41. |
| Backward Compatibility | ✅ Compliant | Default template `doc.doc.md/templates/default.md` renders identically under the new engine. Legacy Bash render comparison test (T40) confirms byte-identical output. All existing test suites pass without modification. |
| Component Placement | ✅ Compliant | `mustache_render.py` placed in `doc.doc.md/components/` alongside existing Python components (`filter.py`, `plugin_info.py`). File is executable (`chmod +x`). |
| Library Dependency | ✅ Compliant | `chevron` is a pure-Python, zero-dependency Mustache renderer licensed under MIT. MIT is compatible with the project's AGPL-3.0 licence. No licence conflict. |
| fileName Derivation | ✅ Compliant | `mustache_render.py` derives `fileName` from `filePath` using `os.path.basename`, replicating the logic previously in Bash. The derived key is injected into the data dict before rendering, ensuring `{{fileName}}` works in all templates. |

## Deviations Found

None.

All changes follow established architecture patterns. The delegation of rendering logic from Bash to Python is consistent with ADR-001 and mirrors the approach already taken by `filter.py` and `plugin_info.py`. The `render_template_json` function signature is unchanged, ensuring all callers continue to work. The `chevron` library dependency is MIT-licensed and compatible with AGPL-3.0.

## Recommendations

- As templates grow in complexity (conditionals, loops over plugin arrays), consider adding a template authoring guide to `doc.doc.md/templates/` documenting the available Mustache syntax and conventions.
- If partials (`{{> partial}}`) are needed in the future, evaluate whether `chevron`'s partial support meets requirements or whether a custom partial resolver is needed.
- Monitor `chevron` library for updates and security advisories, though as a pure-Python zero-dependency library the risk surface is minimal.

## Conclusion

FEATURE_0040 is **architecturally compliant**. The full Mustache template support implementation delegates rendering from the Bash string-substitution loop in `templates.sh` to a standalone Python script (`mustache_render.py`) using the `chevron` library. ADR-001, ADR-003, and ADR-004 are fully met. The function signature and exit code contract are preserved, ensuring backward compatibility with all callers. REQ_0007 and REQ_0009 are implemented. REQ_SEC_004 is satisfied — no `eval`/`exec` is used, and Mustache by design does not execute code. No deviations or concerns were identified.
