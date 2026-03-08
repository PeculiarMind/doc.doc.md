# Bug: markitdown Plugin install.sh Missing Optional Extras

- **ID:** BUG_0013
- **Priority:** High
- **Type:** Bug
- **Created at:** 2026-03-08
- **Created by:** Product Owner
- **Status:** DONE

## TOC
1. [Overview](#overview)
2. [Symptoms](#symptoms)
3. [Root Cause](#root-cause)
4. [Expected Behaviour](#expected-behaviour)
5. [Steps to Reproduce](#steps-to-reproduce)
6. [Acceptance Criteria](#acceptance-criteria)
7. [Dependencies](#dependencies)
8. [Related Links](#related-links)

## Overview

The markitdown plugin's `install.sh` script executes `pip install markitdown` without any optional extras. Since markitdown 0.1.0, file format support for PPTX, DOCX, XLSX, and XLS has been split into optional dependency groups (`[pptx]`, `[docx]`, `[xlsx]`, `[xls]`). The bare install therefore succeeds (the CLI binary is present) but the `installed` check reports true while the plugin is functionally unable to convert any of the MS Office documents it advertises support for.

This also impacts the `setup` routine (`./doc.doc.sh setup`), which calls `install.sh` and declares success, leaving the user with a broken plugin.

## Symptoms

- Running `./doc.doc.sh setup` completes without error, markitdown is reported as installed.
- Attempting to process a DOCX/XLSX/PPTX/XLS file via the markitdown plugin fails with a markitdown conversion error because the optional format libraries (e.g. `python-docx`, `openpyxl`, `python-pptx`, `xlrd`) are not present.

## Root Cause

`doc.doc.md/plugins/markitdown/install.sh` executes:
```bash
pip install markitdown
```

This installs only the markitdown base package. Since v0.1.0, optional format extras must be specified explicitly:
- `[pptx]` — PowerPoint support
- `[docx]` — Word document support
- `[xlsx]` — Excel (modern) support
- `[xls]` — Excel (legacy) support

Per the official markitdown README:
> Dependencies are now organized into optional feature-groups. Use `pip install 'markitdown[all]'` for backward-compatible behavior.

## Expected Behaviour

`install.sh` should install markitdown with the required optional extras for the file formats the plugin supports — specifically `pptx`, `docx`, `xlsx`, and `xls`:
```bash
pip install 'markitdown[pptx,docx,xlsx,xls]'
```

Only these four extras are needed (no PDF, audio, YouTube, etc.) to match the plugin's declared supported MIME types.

## Steps to Reproduce

1. Run `sudo ./doc.doc.sh setup` and answer `y` to install markitdown.
2. Verify markitdown is reported as installed.
3. Run `echo '{"filePath":"tests/docs/README-MSWORD.docx","mimeType":"application/vnd.openxmlformats-officedocument.wordprocessingml.document"}' | bash doc.doc.md/plugins/markitdown/main.sh`
4. Observe conversion failure because optional DOCX dependencies are missing.

## Acceptance Criteria

- [ ] `install.sh` installs `markitdown[pptx,docx,xlsx,xls]` (not bare `markitdown`)
- [ ] After installation, the markitdown plugin can successfully convert a DOCX, XLSX, PPTX, and XLS file
- [ ] The `installed` check (`installed.sh`) remains valid (markitdown CLI binary present)
- [ ] Running `./doc.doc.sh setup` results in a fully functional markitdown plugin that can process all four MS Office formats
- [ ] Existing tests for the markitdown plugin continue to pass
- [ ] A regression test verifies the install command uses the correct extras

## Dependencies
- FEATURE_0017 (markitdown MS Office plugin)
- FEATURE_0025 (interactive setup routine)
- REQ_0026 (Install Plugin Command)

## Related Links
- markitdown README: https://github.com/microsoft/markitdown/blob/main/README.md
- Plugin install script: `doc.doc.md/plugins/markitdown/install.sh`
- Setup routine: `doc.doc.md/components/plugin_management.sh`
