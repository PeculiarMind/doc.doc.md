# ADR: Default Template Fallback Logic

## Status
Accepted

## Context
The system must provide a default template if the user does not specify one, to ensure report generation always succeeds.

## Decision
- If no template is specified, the system uses a default template from `templates/builtin/default.md`
- Fallback logic is implemented in the report generation pipeline
- The fallback is documented in the runtime view and concepts

## Consequences
- Users always receive a report, even if they do not provide a template
- The default template can be updated or overridden by users

## Related Features
- feature_0027_default_template_fallback
