# Security Review: FEATURE_0046 — CRM114 Text Classification Plugin

- **Report ID:** SECREV_026
- **Work Item:** FEATURE_0046
- **Date:** 2026-03-18
- **Agent:** security.agent
- **Status:** Approved

## Scope

Security review of the `crm114` plugin implementation:

| File | Review Focus |
|------|-------------|
| `doc.doc.md/plugins/crm114/process.sh` | Input validation, path handling, external command invocation |
| `doc.doc.md/plugins/crm114/learn.sh` | Category name sanitization, path traversal, stdin handling |
| `doc.doc.md/plugins/crm114/unlearn.sh` | Category name sanitization, path traversal, graceful failure |
| `doc.doc.md/plugins/crm114/listCategories.sh` | pluginStorage validation, directory traversal |
| `doc.doc.md/plugins/crm114/manageCategories.sh` | Interactive input sanitization, path traversal |
| `doc.doc.md/plugins/crm114/train.sh` | JSON input validation, interactive path handling |
| `doc.doc.md/plugins/crm114/install.sh` | Privilege escalation, external command execution |
| `doc.doc.md/plugins/crm114/installed.sh` | Minimal attack surface |

## Assessment

| Finding | Severity | Status |
|---------|----------|--------|
| All reviewed areas | — | No significant finding |

## Analysis

### 1. Path Traversal Prevention — pluginStorage (REQ_SEC_005)

All scripts that accept a `pluginStorage` field apply a `[[ "$PLUGIN_STORAGE" == *".."* ]]` guard before any file I/O. This prevents `../` components from reaching system directories. While a `readlink -f` canonicalization would be more thorough, the `..` substring check is consistent with the pattern used throughout the codebase (e.g., `cmd_run`, `cmd_loop`) and is sufficient for defense-in-depth.

Scripts reviewed: `process.sh`, `learn.sh`, `unlearn.sh`, `listCategories.sh`, `manageCategories.sh`, `train.sh`.

### 2. Category Name Sanitization (REQ_SEC_005)

`learn.sh` and `unlearn.sh` validate the `category` field against `^[A-Za-z0-9._-]+$` before constructing the CSS file path. This whitelist approach correctly prevents:
- Path traversal: `../`, `../../`
- Shell injection via forward slash: `cat/other`
- Shell metacharacters: `;`, `|`, `>`, `` ` ``, `$`, `*`, space

The constructed path `"$PLUGIN_STORAGE/$CATEGORY.css"` is safe given both components are validated.

### 3. Stdin Size Limiting (REQ_SEC_009)

All non-interactive scripts source `plugin_input.sh` which enforces a 1MB stdin limit via `head -c 1048576`. This prevents memory exhaustion from oversized inputs.

### 4. External Command Invocation (csslearn, cssunlearn, crmclassify)

Text is passed to CRM114 tools via stdin: `printf '%s\n' "$TEXT" | csslearn "$CSS_FILE"`. The CSS file path is the only argument, and it is composed solely of the validated `pluginStorage` and sanitized `category` name. No user-controlled data is interpolated into command-line arguments.

`crmclassify` in `process.sh` is called with an array of CSS file paths derived from `find`. The `find` output is limited to `$PLUGIN_STORAGE` with `-maxdepth 1 -name "*.css"`, confining results to the validated storage directory.

### 5. Interactive Input Handling (manageCategories.sh, train.sh)

Both scripts read user input from `/dev/tty` directly, not stdin. Input for category names in `manageCategories.sh` is validated against the same `^[A-Za-z0-9._-]+$` whitelist before file creation. No shell eval or unquoted variable expansion is used with user-provided values.

### 6. File Existence Checks Before Write

`unlearn.sh` checks for the CSS file's existence before calling `cssunlearn`, preventing blind writes to unexpected paths. `learn.sh` delegates creation to `csslearn` which handles initialization.

### 7. install.sh — Privilege Escalation

`install.sh` calls `apt-get install` and `brew install`. These commands may require elevated privileges. The script does not use `sudo` itself; if elevated privileges are needed, they must be provided by the caller. This is consistent with how other plugins handle installation (e.g., `ocrmypdf/install.sh`).

### 8. Threat Modeling Summary (STRIDE)

| Threat | Category | Mitigated? | Notes |
|--------|----------|------------|-------|
| Path traversal via pluginStorage | Elevation of Privilege | ✅ Yes | `..` substring check |
| Command injection via category name | Tampering | ✅ Yes | Whitelist regex |
| Large input DoS | Denial of Service | ✅ Yes | 1MB stdin limit via plugin_input.sh |
| Shell injection via text content | Tampering | ✅ Yes | Text passed via stdin, not args |
| Unauthorized file access via find | Elevation of Privilege | ✅ Yes | `-maxdepth 1` + `-name "*.css"` limits scope |

## Security Concept Update

No changes to the security concept are required. The crm114 plugin applies all existing security patterns (REQ_SEC_005, REQ_SEC_009) consistently with other plugins.

## Verdict

**Approved.** The implementation applies path traversal prevention, input sanitization, and safe command invocation patterns consistently across all scripts. No new attack surfaces or vulnerabilities were identified.
