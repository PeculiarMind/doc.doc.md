# Feature: Interactive Setup Routine

- **ID:** FEATURE_0025
- **Priority:** High
- **Type:** Feature
- **Created at:** 2026-03-06
- **Created by:** Product Owner
- **Status:** BACKLOG

## Overview
Provide an interactive `setup` command that walks the user through verifying and installing all core dependencies of `doc.doc.md`, then discovers all available plugins, checks their installation and activation state, and — for each inactive plugin — prompts the user interactively whether to install and/or activate it.

Typical invocation:
```
./doc.doc.sh setup
```

## Acceptance Criteria

### Core dependency checks
- [ ] The command checks every mandatory system dependency required by `doc.doc.md` (e.g. `jq`, `column`, `awk`, `sed`, `find`) and reports their status (found / missing)
- [ ] For each missing mandatory dependency the command attempts to install it automatically (using the host package manager) and reports the result
- [ ] If a mandatory dependency cannot be installed automatically, the command prints a clear actionable error message and exits with a non-zero code

### Plugin discovery and status
- [ ] All available plugins (i.e. every plugin with a `descriptor.json` present in `doc.doc.md/plugins/`) are discovered and listed
- [ ] For each plugin the command checks whether it is installed (via the plugin's `installed` command) and whether it is activated
- [ ] The combined status (installed / not-installed, active / inactive) is shown to the user in a summary table before prompting begins

### Interactive prompting
- [ ] For each plugin that is **not installed**, the user is asked: *"Plugin <name> is not installed. Install now? [y/N]"*. A `y` answer triggers the plugin's `install` command.
- [ ] For each plugin that is **installed but not activated**, the user is asked: *"Plugin <name> is installed but inactive. Activate now? [y/N]"*. A `y` answer activates the plugin.
- [ ] Prompts are skipped (treated as "no") when stdin is not a terminal (non-interactive / piped mode), so the command is safe to use in scripts
- [ ] A `--yes` / `-y` flag auto-answers "yes" to all prompts, enabling fully automated setup
- [ ] A `--non-interactive` / `-n` flag suppresses all prompts and only reports status (equivalent to a dry-run check)

### Output and UX
- [ ] Output is structured: dependency check section, then plugin status section, then interactive prompts, then final summary
- [ ] Final summary states how many dependencies were already satisfied, how many were installed, how many plugins were activated, and whether any action failed
- [ ] All output follows the existing UI conventions defined in `doc.doc.md/components/ui.sh`
- [ ] Errors and warnings are printed to stderr; informational output to stdout

### Backward compatibility & integration
- [ ] The new `setup` command is listed in the main help/usage output
- [ ] Existing commands and tests are unaffected (REQ_0038)
- [ ] The command is covered by at least one integration test in `tests/`

## Dependencies
- REQ_0003 (Plugin-Based Architecture)
- REQ_0006 (User-Friendly Interface)
- REQ_0024 (Activate Plugin Command)
- REQ_0026 (Install Plugin Command)
- REQ_0027 (Check Plugin Installation Command)
- REQ_0038 (Backward-Compatible CLI)
- FEATURE_0011 (install all plugins — baseline install logic)
- FEATURE_0012 (activate plugin — baseline activate logic)
- FEATURE_0015 (installed check command — baseline installed-check logic)

## Related Links
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-system.md`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0006_user-friendly-interface.md`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0026_install-plugin.md`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0027_check-plugin-installed.md`
- UI module: `doc.doc.md/components/ui.sh`
- Plugin management module: `doc.doc.md/components/plugin_management.sh`
