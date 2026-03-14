# Architecture Review: FEATURE_0042 CRM114 Model Management Commands

- **ID:** ARCHREV_019
- **Created at:** 2026-03-14
- **Created by:** architect.agent
- **Work Item:** [FEATURE_0042: CRM114 Model Management Commands](../../03_plan/02_planning_board/06_done/FEATURE_0042_crm114-model-management-commands.md)
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
| `doc.doc.md/plugins/crm114/learn.sh` (new) | Non-interactive command: reads JSON from stdin (category, pluginStorage, filePath), trains category model via `csslearn` |
| `doc.doc.md/plugins/crm114/unlearn.sh` (new) | Non-interactive command: reads JSON from stdin (category, pluginStorage, filePath), removes text from model via `cssunlearn` |
| `doc.doc.md/plugins/crm114/listCategories.sh` (new) | Lists all `.css` model files in pluginStorage; outputs `{"categories": [...]}` |
| `doc.doc.md/plugins/crm114/train.sh` (new) | Interactive training loop: positional args (pluginStorage, input_dir), invokes `doc.doc.sh process` for text extraction |
| `doc.doc.md/plugins/crm114/descriptor.json` (updated) | Registers train, learn, unlearn, listCategories commands with input/output schemas |
| `tests/test_feature_0042.sh` (new) | 62 tests covering structure, validation, functionality, and security |

## Architecture Vision Reference

- **ADR-001:** [Mixed Bash/Python Implementation](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_001_mixed_bash_python_implementation.md) — all new commands are Bash scripts consistent with existing plugin command style
- **ADR-003:** [JSON Plugin Descriptors](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md) — learn, unlearn, listCategories follow JSON stdin/stdout protocol; all registered in descriptor.json
- **ADR-004:** [Plugin Exit Code Strategy](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md) — learn/unlearn/listCategories use 0 (success) and 1 (error) as mandated for management commands
- **REQ_0003:** [Plugin-Based Architecture](../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-system.md) — commands implemented as plugin scripts, registered in descriptor.json
- **REQ_0029:** [Plugin State Storage](../../02_project_vision/02_requirements/03_accepted/REQ_0029_plugin-state-storage.md) — all .css model files stored exclusively in `pluginStorage`; no state written elsewhere
- **REQ_SEC_005:** [Path Traversal Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md) — pluginStorage and category name validation before any file I/O

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| ADR-001: Bash Implementation | ✅ Compliant | All four commands are pure Bash scripts. No new Python components introduced. Consistent with existing plugin command style (install.sh, installed.sh, main.sh). |
| ADR-003: JSON Plugin Descriptors | ✅ Compliant | learn, unlearn, listCategories follow the established JSON stdin/stdout protocol. All four commands are registered in descriptor.json with complete input/output schemas. train uses positional arguments (interactive mode) — this is a legitimate deviation for interactive commands and is documented in the descriptor schema. |
| ADR-004: Exit Code Strategy | ✅ Compliant | learn, unlearn, listCategories: exit 0 on success, exit 1 on error. train: exit 0 on completion, exit 1 on argument/validation errors. No exit 65 used for management commands (correct — skip is only for process pipeline). |
| REQ_0003: Plugin Architecture | ✅ Compliant | All commands are self-contained Bash scripts. Registered in descriptor.json. Invoked via standard plugin infrastructure. |
| REQ_0029: Plugin State Storage | ✅ Compliant | All .css model files are stored exclusively under the `pluginStorage` directory. No state is written outside pluginStorage. The `listCategories` command reads .css files only from the canonical pluginStorage path. |
| REQ_SEC_005: Path Traversal | ✅ Compliant | pluginStorage resolved via `readlink -f` before any file I/O. Category name validated with `^[a-zA-Z0-9._-]+$` regex to prevent path traversal. CSS file path verified to remain under canonical pluginStorage. |
| Shared Input Helpers | ✅ Compliant | learn.sh and unlearn.sh source `plugin_input.sh` for JSON reading and filePath validation, consistent with main.sh. listCategories.sh uses `plugin_input.sh` for JSON reading and pluginStorage extraction. |
| No Temporary Files | ✅ Compliant | Text content is read from file and piped directly to csslearn/cssunlearn via stdin. No temporary files are created. |
| train Invokes doc.doc.sh | ✅ Compliant | train.sh invokes `doc.doc.sh process` as a subprocess (loose coupling as specified in FEATURE_0003). Path to doc.doc.sh is resolved relative to the plugin directory (`../../../doc.doc.sh`). |
| Descriptor Schema | ✅ Compliant | descriptor.json updated with complete input/output schemas for all four new commands. Existing commands (process, install, installed) unchanged. |

## Deviations Found

None.

The `train` command uses positional command-line arguments instead of JSON stdin, which differs from the typical plugin command pattern. This is an intentional and appropriate design choice: `train` is an interactive command requiring a TTY and user input, making JSON stdin unsuitable. The deviation is documented in the descriptor schema. The pattern is consistent with how `install.sh` and `installed.sh` take no stdin input.

## Recommendations

1. Consider adding a `cssutil` availability check in `installed.sh` alongside the existing `crm` / `cssutil` check — since `csslearn` and `cssunlearn` are now required for the new commands, the installed check should reflect their availability.
2. The `train.sh` doc.doc.sh path resolution (`../../../doc.doc.sh`) is functional but fragile if the plugin directory structure changes. A future refactor could use an environment variable or a standard path-finding mechanism. This is low-priority technical debt.

## Conclusion

**Status: Compliant** — The implementation aligns with all relevant ADRs and architectural requirements. The four new commands follow established plugin patterns, use the shared input helpers, store state exclusively in pluginStorage, and validate all inputs before any file I/O. No architectural remediation is required.
