# ADR: Template Directory Structure

## Status
Accepted

## Context
The system must support both built-in and user-provided templates for report generation. A clear directory structure is needed to ensure discoverability, override rules, and extensibility.

## Decision
- Built-in templates are stored in `templates/builtin/`
- User templates are stored in `templates/user/`
- The system searches user templates first, then built-in
- Directory names and structure are documented in the concepts section

## Consequences
- Users can override built-in templates by providing a template with the same name in the user directory
- New template types can be added by extending the directory structure

## Related Features
- feature_0026_templates_directory_structure
