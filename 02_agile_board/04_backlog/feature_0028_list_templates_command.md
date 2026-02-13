# Feature: List Templates Command

**ID**: 0028  
**Type**: Feature Implementation  
**Status**: Backlog  
**Created**: 2026-02-12  
**Priority**: Low

## Overview
Implement `--list-templates` command-line option to display all available templates in the templates directory, enabling template discovery and selection similar to the existing `--list-plugins` functionality.

## Description
Add a new CLI command that enumerates and displays all available Markdown templates from the `scripts/templates/` directory. The command provides users with an overview of available template options, shows template names and descriptions (from metadata or inline comments), distinguishes template types (per-file vs. aggregated), indicates which template is the default, and exits after displaying the list without performing analysis. This feature mirrors the successful pattern established by the `--list-plugins` command (feature_0003), providing consistent UX for system capability discovery.

The listing helps users understand what templates are available, when to use each template, and how to specify them via the `-m` flag.

## Business Value
- **Improves discoverability** - users can discover available templates
- **Reduces documentation dependency** - self-documenting through CLI
- **Mirrors successful pattern** - consistent with `--list-plugins` UX
- **Supports template exploration** - encourages template customization
- **Professional CLI experience** - completeness and consistency
- **Enables scripting** - machine-readable template discovery for automation

## Related Requirements
- [req_0024](../../01_vision/02_requirements/03_accepted/req_0024_plugin_listing.md) - Plugin Listing (pattern to mirror)
- [req_0034](../../01_vision/02_requirements/03_accepted/req_0034_default_template_provision.md) - Default Template Provision
- [req_0042](../../01_vision/02_requirements/03_accepted/req_0042_advanced_help_system.md) - Advanced Help System (template help integration)

## Architecture References
- [CLI Interface Concept 08_0003](../../01_vision/03_architecture/08_concepts/08_0003_cli_interface_concept.md) - CLI patterns and conventions
- [Template Engine Concept 08_0011](../../01_vision/03_architecture/08_concepts/08_0011_template_engine.md) - Template system
- Feature [0003 Plugin Listing](../06_done/feature_0003_plugin_listing.md) - Reference implementation pattern

## Acceptance Criteria

### Command-Line Interface
- [ ] `--list-templates` flag added to argument parser
- [ ] Alternative short form `-l templates` supported (optional)
- [ ] Command exits successfully after listing (exit code 0)
- [ ] Command does not require `-d` or `-t` arguments
- [ ] Invalid subcommands show error: "Unknown list command: {command}"

### Template Discovery
- [ ] System enumerates templates from `scripts/templates/` directory
- [ ] System discovers templates from `scripts/templates/examples/` subdirectory
- [ ] System identifies template files by `.md` extension
- [ ] System handles empty templates directory gracefully
- [ ] System handles missing templates directory with clear error

### Template Metadata Extraction
- [ ] System extracts template name from filename or frontmatter
- [ ] System extracts description from frontmatter or first comment block
- [ ] System identifies template type (per-file, aggregated, example)
- [ ] System identifies default template(s)
- [ ] System gracefully handles templates without metadata

### Display Format
- [ ] Templates listed in readable table format
- [ ] Output includes: Name, Type, Description, Path
