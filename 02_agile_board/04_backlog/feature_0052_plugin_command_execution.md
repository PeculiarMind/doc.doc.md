# Feature: Plugin Command Execution Interface

**ID**: feature_0052_plugin_command_execution  
**Status**: Backlog  
**Created**: 2026-02-14  
**Last Updated**: 2026-02-14

## Overview
Implement a command-line interface for executing plugin-specific commands through doc.doc.sh, enabling plugins to expose custom operations like training, configuration, diagnostics, and maintenance tasks.

## Description
This feature extends the plugin system to support plugin-specific commands beyond file analysis. Plugins can declare custom operations in their descriptors, and users can invoke these operations through a unified CLI interface: `./doc.doc.sh -p exec <PLUGIN_NAME> <COMMAND> [PARAMS...]`.

**Motivating Use Case**: The bogofilter plugin needs training commands to build category classifiers:
```bash
# Train categories with example documents
./doc.doc.sh -p exec bogofilter train technical --positive tech_docs/ --negative general_docs/

# Check training status
./doc.doc.sh -p exec bogofilter status technical

# List trained categories
./doc.doc.sh -p exec bogofilter list-categories
```

**Implementation Components**:
- Extend plugin descriptor schema to include `commands` section
- Add `-p exec` option parsing to CLI component
- Implement plugin command router that:
  - Validates plugin exists and is enabled
  - Validates command exists in plugin descriptor
  - Invokes plugin command handler script
  - Passes parameters and provides plugin context
  - Captures output and exit codes
- Create plugin command handler framework/helpers
- Implement security controls (sandboxing if applicable)
- Add help system for plugin commands

**Plugin Descriptor Extension**:
```json
{
  "name": "bogofilter",
  "description": "...",
  "commands": [
    {
      "name": "train",
      "description": "Train a classification category with positive/negative examples",
      "usage": "train <CATEGORY> --positive <DIR> --negative <DIR>",
      "handler": "commands/train.sh",
      "parameters": [
        {"name": "category", "required": true, "description": "Category name"},
        {"name": "--positive", "required": true, "description": "Directory with positive examples"},
        {"name": "--negative", "required": true, "description": "Directory with negative examples"}
      ]
    },
    {
      "name": "status",
      "description": "Show training status for a category",
      "usage": "status <CATEGORY>",
      "handler": "commands/status.sh"
    },
    {
      "name": "list-categories",
      "description": "List all trained categories",
      "usage": "list-categories",
      "handler": "commands/list_categories.sh"
    }
  ]
}
```

**Command Handler Scripts**:
Each plugin can provide command handler scripts that receive:
- Command parameters as arguments
- Environment variables with plugin context (plugin dir, workspace dir, etc.)
- Access to common utilities (logging, error handling)

Example: `scripts/plugins/ubuntu/bogofilter/commands/train.sh`

**User Experience Flow**:
1. User invokes: `./doc.doc.sh -p exec bogofilter train technical --positive tech/ --negative general/`
2. CLI parser extracts: plugin="bogofilter", command="train", params=["technical", "--positive", "tech/", "--negative", "general/"]
3. System loads plugin descriptor and validates command exists
4. System invokes handler: `bogofilter/commands/train.sh technical --positive tech/ --negative general/`
5. Handler executes training logic and outputs progress/results
6. System captures output and exit code, returns to user

## Traceability
- **Primary**: [req_0076](../../01_vision/02_requirements/01_funnel/req_0076_plugin_command_execution.md) - Plugin Command Execution Interface
- **Related**: [req_0022](../../01_vision/02_requirements/03_accepted/req_0022_plugin_based_extensibility.md) - Plugin-based Extensibility
- **Related**: [req_0024](../../01_vision/02_requirements/03_accepted/req_0024_plugin_listing.md) - Plugin Listing (similar -p pattern)
- **Related**: [req_0047](../../01_vision/02_requirements/03_accepted/req_0047_plugin_descriptor_validation.md) - Plugin Descriptor Validation
- **Related**: [req_0075](../../01_vision/02_requirements/01_funnel/req_0075_bogofilter_spam_analysis_plugin.md) - Bogofilter Plugin (primary use case)
- **Architecture**: [Concept 08_0001](../../01_vision/03_architecture/08_concepts/08_0001_plugin_concept.md) - Plugin Concept
- **Architecture**: [Concept 08_0003](../../01_vision/03_architecture/08_concepts/08_0003_cli_interface_concept.md) - CLI Interface Concept

## Acceptance Criteria

### CLI Interface
- [ ] System accepts `-p exec <PLUGIN_NAME> <COMMAND> [PARAMS...]` syntax
- [ ] System accepts `--plugins exec` as alternative to `-p exec`
- [ ] Option parsing extracts plugin name, command name, and parameters correctly
- [ ] Parameters with spaces, quotes, and special characters handled properly
- [ ] `-p exec` without arguments shows usage help
- [ ] `-p exec <PLUGIN_NAME>` without command shows available commands for that plugin
- [ ] `-p exec <PLUGIN_NAME> help` shows detailed help for plugin commands
- [ ] `-p exec --help` shows generic help about plugin command execution feature

### Plugin Descriptor Schema
- [ ] Descriptor schema extended to include optional `commands` array
- [ ] Each command declaration includes: name, description, usage, handler path
- [ ] Command parameters can be documented (name, type, required, description)
- [ ] Descriptor validation (req_0047) validates command declarations
- [ ] Malformed command declarations reported with clear errors
- [ ] Backward compatibility: plugins without `commands` section work normally

### Command Routing & Execution
- [ ] System loads plugin descriptor for specified plugin
- [ ] System validates plugin exists and is enabled
- [ ] System validates command exists in plugin descriptor
- [ ] System resolves handler script path relative to plugin directory
- [ ] System validates handler script exists and is executable
- [ ] System invokes handler script with command parameters
- [ ] Handler receives parameters as command-line arguments
- [ ] Handler receives plugin context via environment variables (PLUGIN_DIR, PLUGIN_NAME, WORKSPACE_DIR if applicable)
- [ ] Handler stdout/stderr displayed to user in real-time
- [ ] Handler exit code propagated to doc.doc.sh exit code
- [ ] System handles long-running commands (no timeout unless configured)

### Error Handling
- [ ] Unknown plugin name: clear error message listing available plugins
- [ ] Unknown command: clear error message listing available commands for that plugin
- [ ] Missing handler script: clear error with handler path
- [ ] Non-executable handler: clear error with permission guidance
- [ ] Handler execution failure: preserve stderr and exit code
- [ ] Invalid parameters: handler can validate and return meaningful errors
- [ ] Plugin disabled: clear error indicating plugin is disabled

### Command Handler Framework
- [ ] Document conventions for handler scripts (location, naming, permissions)
- [ ] Provide template/example handler script
- [ ] Define standard environment variables available to handlers
- [ ] Handlers can access logging utilities from doc.doc.sh
- [ ] Handlers can access configuration/workspace utilities
- [ ] Handlers follow same security model as plugin execution

### Security
- [ ] Command handlers execute with same user permissions as doc.doc.sh
- [ ] If sandboxing (req_0048) implemented, evaluate if commands should be sandboxed
- [ ] Document security considerations for command handlers
- [ ] Validate handler paths to prevent path traversal attacks
- [ ] Consider whether commands need different permissions than analysis operations

### Documentation
- [ ] Feature usage documented in README or CLI documentation
- [ ] Plugin developers' guide explains how to add commands to plugins
- [ ] Command descriptor schema documented
- [ ] Handler script conventions documented
- [ ] Example plugins with commands provided (bogofilter train, status, etc.)
- [ ] Help system integrated: `-p exec --help`, `-p exec <PLUGIN> help`

### Integration & Testing
- [ ] CLI option parsing tested with various argument combinations
- [ ] Command routing tested with valid and invalid plugins/commands
- [ ] Handler execution tested with different parameter types
- [ ] Exit code propagation tested
- [ ] Error scenarios tested (missing plugin, missing command, handler failures)
- [ ] Integration with existing `-p list` command (may show command count or indicator)
- [ ] Verbose mode (-v) properly propagates to command handlers
- [ ] System tests demonstrate end-to-end command execution

### Example Implementation: Bogofilter Commands
- [ ] Bogofilter plugin extended with `commands` section in descriptor
- [ ] Bogofilter `train` command implemented with positive/negative example processing
- [ ] Bogofilter `status` command shows training statistics per category
- [ ] Bogofilter `list-categories` command lists all trained databases
- [ ] Bogofilter command handlers documented as reference examples
- [ ] Bogofilter commands tested with real training workflows

## Dependencies
- Plugin architecture (req_0022) - DONE
- Plugin listing (feature implementing req_0024) - MAY BE IN BACKLOG
- Plugin descriptor validation (req_0047) - DONE
- CLI interface (req_0017) - DONE
- Bogofilter plugin (feature_0051) - IN BACKLOG (motivating use case)

## Technical Notes

### Command Handler Environment Variables
```bash
# Available to all command handlers
PLUGIN_NAME="bogofilter"
PLUGIN_DIR="/path/to/scripts/plugins/ubuntu/bogofilter"
PLUGIN_DESCRIPTOR="$PLUGIN_DIR/descriptor.json"
WORKSPACE_DIR="/path/to/workspace"  # if -w specified
DOC_DOC_ROOT="/path/to/doc.doc.md"
DOC_DOC_VERBOSE="true"  # if -v specified
```

### Handler Script Example
```bash
#!/usr/bin/env bash
# scripts/plugins/ubuntu/bogofilter/commands/train.sh

set -euo pipefail

CATEGORY="${1:-}"
if [[ -z "$CATEGORY" ]]; then
    echo "Error: Category name required" >&2
    echo "Usage: $0 <CATEGORY> --positive <DIR> --negative <DIR>" >&2
    exit 1
fi

# Parse --positive and --negative directories
# Train bogofilter database for category
# Output progress and results

echo "Training category '$CATEGORY'..."
# Implementation here
```

### Plugin Descriptor Command Section Example
```json
{
  "name": "bogofilter",
  "description": "Multi-category text classification using Bayesian analysis",
  "active": true,
  "processes": { ... },
  "consumes": { ... },
  "provides": { ... },
  "commandline": "...",
  "commands": [
    {
      "name": "train",
      "description": "Train a classification category with example documents",
      "usage": "train <CATEGORY> --positive <DIR> --negative <DIR>",
      "handler": "commands/train.sh",
      "parameters": [
        {"name": "category", "required": true, "position": 1},
        {"name": "--positive", "required": true, "type": "directory"},
        {"name": "--negative", "required": true, "type": "directory"}
      ]
    },
    {
      "name": "status",
      "description": "Show training status and statistics for a category",
      "usage": "status <CATEGORY>",
      "handler": "commands/status.sh",
      "parameters": [
        {"name": "category", "required": true, "position": 1}
      ]
    },
    {
      "name": "list-categories",
      "description": "List all trained category databases",
      "usage": "list-categories",
      "handler": "commands/list_categories.sh"
    }
  ]
}
```

### Usage Examples
```bash
# Train bogofilter category
./doc.doc.sh -p exec bogofilter train technical \
  --positive ~/samples/technical/ \
  --negative ~/samples/general/

# Check training status
./doc.doc.sh -p exec bogofilter status technical

# List all trained categories
./doc.doc.sh -p exec bogofilter list-categories

# Get help for bogofilter commands
./doc.doc.sh -p exec bogofilter help

# General help for plugin command execution
./doc.doc.sh -p exec --help
```

## Notes
- Created by Requirements Engineer Agent from req_0076
- Priority: Medium
- Type: Feature Enhancement
- Classification: Plugin System Extension
- This feature significantly enhances plugin capabilities beyond passive analysis
- Enables plugins to be fully self-contained with their own management interfaces
- Maintains unified UX through single entry point (doc.doc.sh)
- Consider future enhancements: command aliases, tab completion, command chaining
- Security consideration: commands may have different risk profiles than analysis operations
