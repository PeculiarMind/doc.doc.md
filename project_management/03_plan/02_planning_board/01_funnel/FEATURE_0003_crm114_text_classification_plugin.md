# CRM114 Text Classification Plugin

- **ID:** FEATURE_0003
- **Priority:** MEDIUM
- **Type:** Feature
- **Created at:** 2026-03-02
- **Created by:** Product Owner
- **Status:** FUNNEL

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

Implement a `crm114` plugin that performs statistical text classification on documents using the CRM114 Discriminator. The plugin stores its classification model files (`.css` database files) in the dedicated plugin state storage directory provided by doc.doc.md via the `pluginStorage` attribute (REQ_0029), keeping all state isolated from the plugin implementation.

**Business Value:**
- Enables automatic text classification of documents in the processed collection
- Demonstrates the plugin state storage mechanism (REQ_0029) with a real-world use case
- Adds a powerful spam/content filtering and categorization capability to the toolchain
- Validates that the `pluginStorage` pattern works correctly for stateful plugins

**What this delivers:**
- `crm114` plugin that classifies a file's text content and returns the classification result and confidence score
- Persistent CRM114 models stored in `pluginStorage` (`.doc.doc.md/crm114/` under the output folder)
- Training commands (`learn`, `unlearn`) to build and refine per-category models from raw text
- `listCategories` command to inspect which categories have trained models in `pluginStorage`
- Standard plugin commands: `process`, `install`, `installed`
- Reference implementation for stateful plugins using `pluginStorage`

## Acceptance Criteria

### crm114 Plugin - process Command (main.sh)

- [ ] `doc.doc.md/plugins/crm114/main.sh` is executable (`chmod +x`)
- [ ] Script reads JSON input from stdin
- [ ] Script parses JSON to extract `filePath` and `pluginStorage` parameters
- [ ] Script validates that `filePath` is provided and file exists
- [ ] Script validates that `pluginStorage` is provided and is a valid directory path
- [ ] Script creates the `pluginStorage` directory if it does not already exist
- [ ] Script uses CRM114 `.css` model files located in `pluginStorage/` for classification
- [ ] If no model files exist yet, script initializes empty CRM114 `.css` files in `pluginStorage/`
- [ ] Script classifies the text content of the file using `crm114`
- [ ] Script outputs valid JSON to stdout with these fields:
  - `classification` (string): The winning class label (e.g., `"spam"`, `"good"`, or custom trained label)
  - `confidence` (number): Classification confidence as a value between 0.0 and 1.0
  - `modelInitialized` (boolean): `true` if models already existed, `false` if they were freshly initialized
- [ ] Script handles errors gracefully (file not found, crm114 not installed, invalid JSON input, unreadable file)
- [ ] Script exits with code 0 on success, 1 on error
- [ ] Script logs errors to stderr (not stdout)
- [ ] Script never writes classification state outside of `pluginStorage`

**Example interaction:**
```bash
echo '{"filePath":"/path/to/doc.txt","pluginStorage":"/out/.doc.doc.md/crm114"}' | ./main.sh
# Output: {"classification":"good","confidence":0.87,"modelInitialized":false}
```

### crm114 Plugin - listCategories Command (list_categories.sh)

- [ ] `doc.doc.md/plugins/crm114/list_categories.sh` is executable (`chmod +x`)
- [ ] Script reads JSON input from stdin
- [ ] Script parses JSON to extract `pluginStorage` parameter
- [ ] Script validates that `pluginStorage` is provided
- [ ] Script scans `pluginStorage/` for `*.css` files and derives category names by stripping the `.css` extension
- [ ] Script outputs valid JSON to stdout with this field:
  - `categories` (array of strings): sorted list of known category names; empty array `[]` if no models exist yet
- [ ] Script exits with code 0 on success, 1 on error
- [ ] Script logs errors to stderr (not stdout)

**Example interaction:**
```bash
echo '{"pluginStorage":"/out/.doc.doc.md/crm114"}' | ./list_categories.sh
# Output: {"categories":["good","spam"]}
```

### crm114 Plugin - learn Command (learn.sh)

- [ ] `doc.doc.md/plugins/crm114/learn.sh` is executable (`chmod +x`)
- [ ] Script reads JSON input from stdin
- [ ] Script parses JSON to extract `category`, `textContent`, and `pluginStorage` parameters
- [ ] Script validates that all three parameters are provided and non-empty
- [ ] Script validates that `pluginStorage` is provided
- [ ] Script creates `pluginStorage` directory if it does not already exist
- [ ] If `pluginStorage/<category>.css` does not exist, script initializes it with `cssutil -b` before learning
- [ ] Script trains the `<category>.css` model with the provided `textContent` using `crm114`
- [ ] Script outputs valid JSON to stdout with these fields:
  - `success` (boolean): `true` if learning succeeded
  - `category` (string): the category that was trained
  - `message` (string): human-readable status message
- [ ] Script exits with code 0 on success, 1 on error
- [ ] Script logs errors to stderr (not stdout)
- [ ] Training data is written exclusively to `pluginStorage/<category>.css`

**Example interaction:**
```bash
echo '{"category":"spam","textContent":"Buy cheap meds now!","pluginStorage":"/out/.doc.doc.md/crm114"}' | ./learn.sh
# Output: {"success":true,"category":"spam","message":"Learned 1 example for category spam"}
```

### crm114 Plugin - unlearn Command (unlearn.sh)

- [ ] `doc.doc.md/plugins/crm114/unlearn.sh` is executable (`chmod +x`)
- [ ] Script reads JSON input from stdin
- [ ] Script parses JSON to extract `category`, `textContent`, and `pluginStorage` parameters
- [ ] Script validates that all three parameters are provided and non-empty
- [ ] Script validates that `pluginStorage/<category>.css` exists; if not, returns error
- [ ] Script removes the provided `textContent` from the `<category>.css` model using `crm114` unlearn
- [ ] Script outputs valid JSON to stdout with these fields:
  - `success` (boolean): `true` if unlearning succeeded
  - `category` (string): the category that was updated
  - `message` (string): human-readable status message
- [ ] Script exits with code 0 on success, 1 on error
- [ ] Script logs errors to stderr (not stdout)

**Example interaction:**
```bash
echo '{"category":"spam","textContent":"Buy cheap meds now!","pluginStorage":"/out/.doc.doc.md/crm114"}' | ./unlearn.sh
# Output: {"success":true,"category":"spam","message":"Unlearned 1 example from category spam"}
```

### crm114 Plugin - installed Command (installed.sh)

- [ ] `doc.doc.md/plugins/crm114/installed.sh` is executable
- [ ] Script checks if `crm114` command is available on the system
- [ ] Script outputs valid JSON to stdout:
  - `installed` (boolean): `true` if `crm114` is available, `false` otherwise
- [ ] Script exits with code 0 (always — reporting status, not failing)

**Example interaction:**
```bash
./installed.sh
# Output: {"installed":true}
```

### crm114 Plugin - install Command (install.sh)

- [ ] `doc.doc.md/plugins/crm114/install.sh` is executable
- [ ] Script checks if `crm114` or `crm` is already available
- [ ] If already available, outputs success immediately
- [ ] If not available, attempts installation via system package manager (`apt`, `brew`, or equivalent)
- [ ] Script outputs valid JSON to stdout:
  - `success` (boolean): `true` if `crm114` or `crm` is available/installed, `false` otherwise
  - `message` (string): Human-readable status message
- [ ] Script exits with code 0 on success, 1 if installation could not be completed

**Example interaction:**
```bash
./install.sh
# Output: {"success":true,"message":"crm114 installed successfully"}
```

### Plugin Descriptor

- [ ] `doc.doc.md/plugins/crm114/descriptor.json` exists and is valid JSON
- [ ] Descriptor declares `pluginStorage` as a required input parameter of type `string` on the `process` command
- [ ] Descriptor declares `filePath` as a required input parameter of type `string` on the `process` command
- [ ] Descriptor declares all output fields (`classification`, `confidence`, `modelInitialized`) with correct types
- [ ] Descriptor declares `listCategories` command with `pluginStorage` as required input and `categories` (array) as output
- [ ] Descriptor declares `learn` command with `category` (string), `textContent` (string), and `pluginStorage` (string) as required inputs, and `success` (boolean), `category` (string), `message` (string) as outputs
- [ ] Descriptor declares `unlearn` command with `category` (string), `textContent` (string), and `pluginStorage` (string) as required inputs, and `success` (boolean), `category` (string), `message` (string) as outputs
- [ ] Descriptor declares `install` and `installed` commands with correct output fields

### State Storage

- [ ] All CRM114 model/database files (`.css`) are written exclusively to `pluginStorage`
- [ ] No state files are written to the plugin directory itself or anywhere else
- [ ] The plugin works correctly when `pluginStorage` points to different paths (portability verified)
- [ ] Model files persist across multiple invocations and are reused

### Code Quality

- [ ] All scripts use `#!/bin/bash` shebang
- [ ] Scripts follow bash best practices (shellcheck passes)
- [ ] JSON parsing uses `jq` for reliability
- [ ] JSON output generation uses `jq` for correct formatting
- [ ] Error messages are clear and actionable
- [ ] Scripts include comments explaining CRM114-specific logic
- [ ] `pluginStorage` path is never hardcoded or constructed — always taken from the input JSON

## Scope

### In Scope
✅ crm114 plugin implementation (main.sh, list_categories.sh, learn.sh, unlearn.sh, install.sh, installed.sh, descriptor.json)  
✅ JSON stdin/stdout communication  
✅ `pluginStorage` integration per REQ_0029  
✅ CRM114 model file initialization and reuse from `pluginStorage`  
✅ Per-category model creation via `learn` command  
✅ Per-category model refinement via `unlearn` command  
✅ Category discovery via `listCategories` command  
✅ Error handling and input validation  
✅ Classification result and confidence score output  

### Out of Scope
❌ Bulk/batch learning from files (single `textContent` string per call only)  
❌ Cross-platform Windows support  
❌ Bulk classification or batch mode  
❌ Integration with any output template variables (future enhancement)  

## Technical Requirements

### Architecture Compliance

- **ADR-003**: JSON stdin/stdout plugin communication
  - Read input as JSON from stdin
  - Write output as JSON to stdout
  - Use lowerCamelCase parameter names
  - Never output non-JSON to stdout (errors to stderr only)

- **REQ_0029 — Plugin State Storage**:
  - Accept `pluginStorage` from the JSON input — never construct or assume this path
  - All CRM114 `.css` database files stored in `pluginStorage/`
  - Create `pluginStorage` directory if it does not exist

- **Plugin Descriptor Contract**:
  - Declare `pluginStorage` as a required `string` input in `descriptor.json`
  - Match all input/output parameter names and types exactly

### Implementation Details

**Model Initialization:**
- CRM114 requires pre-created `.css` files before it can classify or learn
- `learn.sh` initializes `pluginStorage/<category>.css` with `cssutil -b` if it does not exist
- `main.sh` (process) initializes any missing `.css` files found in `pluginStorage/` before classifying

**Classification Invocation (`main.sh`):**
- Pipe file content to `crm114` using a classification CRM script
- Parse CRM114's stdout for the winning class and pR (probability ratio) score
- Convert pR score to a 0.0–1.0 confidence value
- Categories are discovered dynamically from `*.css` files in `pluginStorage/`

**Learning Invocation (`learn.sh`):**
- Initialize `pluginStorage/<category>.css` with `cssutil -b` if absent
- Pipe `textContent` to `crm114` learn command targeting `<category>.css`
- CRM114 learn invocation: `echo "$textContent" | crm114 learn.crm -- --learnto <category>.css`

**Unlearning Invocation (`unlearn.sh`):**
- Validate `pluginStorage/<category>.css` exists (error if not)
- Pipe `textContent` to `crm114` unlearn command targeting `<category>.css`
- CRM114 unlearn invocation: `echo "$textContent" | crm114 learn.crm -- --unlearnfrom <category>.css`

**Category Listing (`list_categories.sh`):**
- Glob `pluginStorage/*.css` and strip the `.css` suffix from each filename
- Return sorted array of category names via `jq -n`

**Storage Layout inside `pluginStorage`:**
```
<pluginStorage>/
  <category>.css    # One CRM114 model file per category (e.g. spam.css, good.css)
  classify.crm      # CRM114 classification script (written by plugin on first run)
  learn.crm         # CRM114 learn/unlearn script (written by plugin on first run)
```

### Required Tools
- bash 4.0+
- jq (JSON processor)
- crm114 (CRM114 Discriminator — installable via `apt install crm114` or `brew install crm114`)

## Dependencies

### Blocking Items
- **REQ_0029** must be accepted and the `pluginStorage` attribute must be passed by doc.doc.md to plugin invocations before this feature can be fully tested end-to-end

### Blocks These Features
None

### Related Requirements
- **REQ_0003**: Plugin-Based Architecture
- **REQ_0029**: Plugin State Storage — core mechanism this feature exercises
- **REQ_SEC_001**: Input Validation and Sanitization
- **REQ_SEC_003**: Plugin Descriptor Validation
- **REQ_SEC_005**: Path Traversal Prevention — `pluginStorage` path must be validated
- **REQ_SEC_009**: JSON Input Validation

## Related Links

### Requirements
- [REQ_0003: Plugin-Based Architecture](../../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-system.md)
- [REQ_0029: Plugin State Storage](../../../02_project_vision/02_requirements/03_accepted/REQ_0029_plugin-state-storage.md)
- [REQ_SEC_001: Input Validation and Sanitization](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_001_input_validation_sanitization.md)
- [REQ_SEC_005: Path Traversal Prevention](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md)
- [REQ_SEC_009: JSON Input Validation](../../../02_project_vision/02_requirements/01_funnel/REQ_SEC_009_json_input_validation.md)

### Architecture Vision
- [ARC_0003: Plugin Architecture](../../../02_project_vision/03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md)

### Existing Plugin Reference Implementations
- [stat plugin](../../../../doc.doc.md/plugins/stat/)
- [file plugin](../../../../doc.doc.md/plugins/file/)
