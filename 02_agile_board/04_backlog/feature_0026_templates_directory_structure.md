# Feature: Templates Directory Structure

**ID**: 0026  
**Type**: Feature Implementation  
**Status**: Backlog  
**Created**: 2026-02-12  
**Priority**: Medium

## Overview
Create an organized `scripts/templates/` directory structure to store default and example templates, replacing the current single template file with a structured template management system.

## Description
Establish a dedicated templates directory under `scripts/templates/` that serves as the central location for all Markdown report templates. This feature reorganizes the current `scripts/template.doc.doc.md` into a structured folder containing a default template and space for additional template variants. The templates directory provides: organized storage for multiple template options, clear template discovery location, support for template categorization (per-file vs. aggregated), example templates for common use cases, and a foundation for template listing and discovery features.

This organizational change improves template management, makes templates more discoverable, and follows established patterns from plugin directory structure.

## Business Value
- **Improves organization** - templates stored in logical, discoverable location
- **Enables template variety** - multiple templates can coexist cleanly
- **Follows established patterns** - mirrors plugin directory structure approach
- **Simplifies template discovery** - users know where to find templates
- **Foundation for advanced features** - enables template listing and management commands
- **Better onboarding** - example templates help users understand customization

## Related Requirements
- [req_0034](../../01_vision/02_requirements/03_accepted/req_0034_default_template_provision.md) - Default Template Provision (mentions example templates directory)
- [req_0005](../../01_vision/02_requirements/03_accepted/req_0005_template_based_reporting.md) - Template-based Reporting
- [req_0004](../../01_vision/02_requirements/03_accepted/req_0004_markdown_report_generation.md) - Markdown Report Generation

## Architecture References
- [CLI Interface Concept 08_0003](../../01_vision/03_architecture/08_concepts/08_0003_cli_interface_concept.md) - Currently shows default template location
- [Template Engine Concept 08_0011](../../01_vision/03_architecture/08_concepts/08_0011_template_engine.md) - Template processing system
- [Deployment View](../../01_vision/03_architecture/07_deployment_view/07_deployment_view.md) - File structure documentation

## Acceptance Criteria

### Directory Structure Creation
- [ ] `scripts/templates/` directory created in project root
- [ ] Default per-file template exists at `scripts/templates/default.md`
- [ ] Optional aggregated template exists at `scripts/templates/default-summary.md`
- [ ] Directory structure follows standard layout (README present)
- [ ] Old `scripts/template.doc.doc.md` migrated or marked deprecated

### Template Organization
- [ ] Templates directory contains README explaining structure and usage
- [ ] Default templates are well-documented with inline comments
- [ ] Example templates provided for common use cases (e.g., minimal, detailed, technical)
- [ ] Template naming convention established and documented
- [ ] Per-file vs. aggregated templates clearly distinguished (naming or subdirectories)

### Integration Impact
- [ ] All references to old template path updated in code
- [ ] Documentation updated to reference new templates directory
- [ ] Existing features (0008, 0010) continue working with new structure
- [ ] Help text (`--help-template`) updated with new template locations
- [ ] Tests updated to use new template paths

### Template Discovery Support
- [ ] Template directory location easily discoverable from script
- [ ] Template files use consistent extension (.md)
