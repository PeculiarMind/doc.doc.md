# Requirement: Plugin Install Script Must Install All Required Optional Dependencies

- **ID:** REQ_0043
- **State:** Accepted
- **Type:** Functional
- **Priority:** High
- **Created at:** 2026-03-08
- **Last Updated:** 2026-03-08

## Overview
A plugin's `install.sh` script must install every optional package extra or transitive dependency required to handle each MIME type and file format declared by the plugin.

## Description
Each plugin declares the file formats (MIME types) it can process, either in `descriptor.json` or in `main.sh`. The plugin's `install.sh` script is the sole installation entry point invoked by the framework. That script must therefore install the full set of dependencies — including optional package extras, language-specific extras syntax (`pip install 'pkg[extra1,extra2]'`), or additional system packages — needed to process every declared MIME type.

A bare install that omits optional extras constitutes an incomplete installation: the plugin will advertise support for file formats it cannot actually process, causing silent failures or runtime errors at processing time.

### Concrete Example (markitdown plugin)
The markitdown plugin declares support for:

| MIME Type | Format | Required extra |
|-----------|--------|----------------|
| `application/vnd.openxmlformats-officedocument.wordprocessingml.document` | .docx | `[docx]` |
| `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`       | .xlsx | `[xlsx]` |
| `application/vnd.openxmlformats-officedocument.presentationml.presentation` | .pptx | `[pptx]` |
| `application/vnd.ms-excel`                                                 | .xls  | `[xls]`  |

The correct install command is therefore:
```
pip install 'markitdown[pptx,docx,xlsx,xls]'
```
A bare `pip install markitdown` omits all four extras and must not be used.

### Rule for Plugin Authors
For every MIME type or file format listed in a plugin's descriptor or processing logic, the corresponding dependency (including optional extras) MUST be present after `install.sh` completes successfully. If an upstream package splits format support into optional extras, the install script must enumerate all required extras explicitly.

## Motivation
- BUG_0013: markitdown `install.sh` used `pip install markitdown` (bare), omitting `[pptx,docx,xlsx,xls]` extras introduced in markitdown 0.1.0 — causing silent conversion failures for all four Office formats.
- [REQ_0026 Install Plugin Command](REQ_0026_install-plugin.md) — governs the install command interface but does not specify what the install script must install internally.
- [REQ_0003 Plugin-Based Architecture](REQ_0003_plugin-system.md) — the plugin contract assumes a fully functional plugin after installation.
- [project_management/02_project_vision/01_project_goals/project_goals.md](../../01_project_goals/project_goals.md) — "Converts supported file types to Markdown."

## Acceptance Criteria
- [ ] The markitdown plugin `install.sh` installs `markitdown[pptx,docx,xlsx,xls]` (all required extras), not bare `markitdown`
- [ ] After running `doc.doc.sh install --plugin markitdown`, processing a `.docx`, `.xlsx`, `.pptx`, and `.xls` file each produces non-empty Markdown output (exit 0)
- [ ] The developer guide plugin-authoring section states that `install.sh` must install all optional extras required for declared MIME types
- [ ] Any new plugin whose upstream package uses optional extras ships an `install.sh` that explicitly enumerates those extras
- [ ] CI/integration tests for the markitdown plugin cover all four Office MIME types end-to-end post-installation

## Related Requirements
- [REQ_0026 Install Plugin Command](REQ_0026_install-plugin.md)
- [REQ_0003 Plugin-Based Architecture](REQ_0003_plugin-system.md)
- [REQ_0042 Plugin Process Exit Code Contract](REQ_0042_plugin-process-exit-code-contract.md)
