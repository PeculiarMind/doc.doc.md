# Templates Directory

This directory contains Markdown report templates used by doc.doc.sh to generate documentation reports.

## Overview

Templates define the structure and formatting of generated documentation reports. Each template uses placeholder variables that are replaced with actual values during report generation.

## Available Templates

### `default.md`
The default template used when no template is explicitly specified via the `-m` flag. This template provides comprehensive metadata and content descriptions for analyzed files.

**Use cases:**
- Quick analysis without specifying a template
- Standard documentation generation
- General-purpose file documentation

**Variables used:**
- `${doc_name}` - Document title/name
- `${doc_categories}` - Document categories
- `${doc_type}` - Type of document
- `${filename}` - File name
- `${filepath_relative}` - Relative path to file
- `${filepath_absolute}` - Absolute path to file
- `${file_owner}` - File owner
- `${file_created_at}` - File creation timestamp
- `${file_created_by}` - File creator
- `${file_last_analyzed_at}` - Last analysis timestamp
- `${doc_doc_version}` - Version of doc.doc tool
- `${doc_content_summary}` - Content description/summary

## Template Format

Templates are Markdown files (`.md` extension) containing:
1. **Static content** - Text, headings, and formatting that appear as-is
2. **Placeholder variables** - `${variable_name}` patterns replaced during rendering
3. **Documentation** - Comments explaining template purpose and usage

## Using Templates

### Default Template (Automatic)
When no template is specified, the system automatically uses `default.md`:
```bash
./scripts/doc.doc.sh -d /path/to/analyze -t /output
```

### Custom Template (Explicit)
Specify a custom template with the `-m` flag:
```bash
./scripts/doc.doc.sh -d /path/to/analyze -m /path/to/template.md -t /output
```

### List Available Templates
To see all available templates:
```bash
./scripts/doc.doc.sh --list-templates
```

## Creating Custom Templates

1. **Copy an existing template** as a starting point
2. **Modify the structure** to match your needs
3. **Use placeholder variables** for dynamic content
4. **Save with `.md` extension** in this directory or elsewhere
5. **Reference with `-m` flag** when running doc.doc.sh

### Template Guidelines

- **Use clear section headings** for organization
- **Include relevant metadata** fields
- **Provide context** through static text
- **Test templates** with real data before deploying
- **Document custom variables** if you add new ones
- **Follow Markdown best practices** for formatting

## Template Discovery

Templates in this directory are:
- Automatically discovered by `--list-templates` command
- Validated during template listing operations
- Accessible via relative or absolute paths

## Migration Note

This templates directory replaces the previous single-file approach (`scripts/template.doc.doc.md`). The old template has been migrated to `default.md` and remains available for backward compatibility references.

## Future Enhancements

Planned template features:
- Template categories (per-file, aggregated, summary)
- Template metadata and frontmatter
- Example templates for specific use cases
- Template validation and linting tools
- Template preview and testing utilities

---

For more information about the template engine, see the architecture documentation in `01_vision/03_architecture/08_concepts/08_0011_template_engine.md`.
