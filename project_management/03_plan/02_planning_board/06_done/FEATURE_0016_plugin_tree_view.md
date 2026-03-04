# Plugin Tree View Command

- **ID:** FEATURE_0016
- **Priority:** Low
- **Type:** Feature
- **Created at:** 2026-03-04
- **Created by:** Product Owner
- **Status:** Done
- **Assigned to:** developer.agent

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Dependencies](#dependencies)
5. [Related Links](#related-links)

## Overview

Implement the `doc.doc.sh tree` command that displays a hierarchical tree view of all plugins, visualizing dependencies between plugins and the activation status of each, using color coding for quick at-a-glance assessment.

**Command signature:**
```
doc.doc.sh tree
```

**Current state:** No `tree` command exists. Users have no visual overview of plugin relationships or activation state.

**Business Value:**
- Provides an intuitive visual map of the plugin ecosystem — dependencies and activation state at a glance
- Helps users understand why a plugin may not be executing (inactive or missing dependency)
- Supports debugging and configuration of complex plugin dependency chains
- Differentiates the tool's UX with a developer-friendly diagnostic feature

**What this delivers:**
- `doc.doc.sh tree` — renders a dependency tree of all plugins in `PLUGIN_DIR`
- Each plugin is shown with its activation status
- Active plugins rendered in **green**, inactive plugins rendered in **red**
- Dependency relationships shown via tree indentation / connectors
- Plugins with no dependencies appear at the root level
- Updated `usage()` help text

## Acceptance Criteria

### Tree Structure

- [ ] `doc.doc.sh tree` exits with code 0
- [ ] All plugins in `PLUGIN_DIR` with a valid `descriptor.json` appear in the output
- [ ] Plugins that are dependencies of other plugins are rendered as children under their consumers
- [ ] Plugins with no dependencies appear at the root level of the tree
- [ ] The tree uses standard ASCII/Unicode connectors (e.g. `├──`, `└──`, `│`) for hierarchy

### Activation Status

- [ ] Each plugin line displays the plugin name and its activation status
- [ ] Active plugins (where `active` is `true` or absent, defaulting to `true`) are rendered in **green** (ANSI color code)
- [ ] Inactive plugins (where `active` is explicitly `false`) are rendered in **red** (ANSI color code)
- [ ] Color is applied consistently for all plugin entries

### Edge Cases

- [ ] If no plugins exist, output is empty and exit code is 0
- [ ] Circular dependencies are detected and reported as an error to stderr (tree may be partial); exit code is non-zero
- [ ] Plugins referencing non-existent dependency plugins show the missing plugin with a warning marker

### Help / Usage

- [ ] `doc.doc.sh --help` output includes `tree`
- [ ] `doc.doc.sh tree --help` describes the command and its color coding semantics

## Scope

**In scope:**
- Tree rendering from `descriptor.json` dependency declarations
- ANSI color coding (green/red) for activation status
- Circular dependency detection
- Missing dependency warnings
- Help/usage text updates

**Out of scope:**
- Interactive or navigable tree (TUI) — output is plain terminal text only
- Showing installation status alongside activation status (that is `installed --plugin` scope)
- Filtering the tree by active/inactive state

## Dependencies

- REQ_0028 (Plugin Tree View) — defines command contract and visual requirements
- REQ_0003 (Plugin-Based Architecture) — plugin discovery and `descriptor.json` structure (dependency declarations)
- FEATURE_0008 (List Plugins Commands, DONE) — establishes `active` field semantics in `descriptor.json`

## Related Links

- Requirements: [REQ_0028](../../../02_project_vision/02_requirements/03_accepted/REQ_0028_plugin-tree-view.md)
- Project Goals: [project_goals.md](../../../02_project_vision/01_project_goals/project_goals.md)
