# Requirement: Plugin Security Documentation

- **ID:** REQ_SEC_007
- **Status:** ACCEPTED
- **Created at:** 2026-02-25
- **Created by:** Security Agent
- **Last Updated:** 2026-03-01
- **Updated by:** Security Agent
- **Source:** Security threat analysis (STRIDE/DREAD Scope 3)
- **Type:** Documentation + Security Requirement
- **Priority:** HIGH
- **Related Threats:** Malicious Plugin Installation, User Unawareness, Social Engineering

## Change History

| Date | Author | Change |
|------|--------|--------|
| 2026-02-25 | Security Agent | Initial requirement created |
| 2026-03-01 | Security Agent | Updated plugin developer guidelines from environment variables to JSON stdin/stdout architecture (ADR-003, ARC_0003) |

## Description

Comprehensive documentation must be provided to educate users about plugin security risks and best practices, and to guide plugin developers in creating secure plugins.

### Specific Requirements

1. **User Documentation** (User Guide):
   - Clear explanation of plugin system security model
   - Risks of installing third-party plugins
   - How to verify plugin sources
   - Built-in vs. third-party plugin distinction
   - How to review plugin code before installation
   - How to report suspicious plugins

2. **Plugin Developer Documentation** (Developer Guide):
   - Secure plugin development guidelines
   - Input validation requirements
   - Output sanitization requirements
   - Resource usage best practices
   - What plugins should NOT do (anti-patterns)
   - Security testing requirements for plugins

3. **In-Application Warnings**:
   - Warning message when installing third-party plugins
   - Clear indication of built-in vs. third-party in plugin list
   - Plugin source information in `list plugins` output
   - Installation confirmation prompt for third-party plugins

4. **Plugin Manifest Documentation**:
   - Security-relevant fields in descriptor.json
   - How to declare dependencies securely
   - System requirements declaration
   - Plugin signing (future) integration

### Security Controls

- **SC-007**: User education reduces plugin security risks
- **SC-003**: Plugin descriptor validation (documented process)

### Required Documentation Sections

#### **User Guide: Plugin Security**

Must include:

1. **Understanding Plugin Risks**:
   ```markdown
   ## Plugin Security
   
   ### What are Plugins?
   Plugins extend doc.doc.md functionality by providing additional file
   processing capabilities. Plugins run with the same permissions as
   doc.doc.md itself.
   
   ### Built-in vs. Third-Party Plugins
   - **Built-in plugins**: Included with doc.doc.md, maintained by core team
   - **Third-party plugins**: Created by community, varying trust levels
   
   ### Security Risks
   ⚠️ **Important**: Plugins execute code on your system and can:
   - Read any file you can read
   - Write any file you can write
   - Execute system commands
   - Access network resources
   - Consume system resources (CPU, memory, disk)
   
   Only install plugins from sources you trust.
   ```

2. **Verifying Plugin Sources**:
   ```markdown
   ### Before Installing a Plugin
   
   1. **Check the source**:
      - Official doc.doc.md plugin repository: ✅ Trusted
      - Well-known developer with good reputation: ⚠️ Verify
      - Unknown source or forum post: ❌ Risky
   
   2. **Review plugin code**:
      - Plugins are shell scripts (main.sh, install.sh, installed.sh)
      - Check descriptor.json for commands plugin will run
      - Look for suspicious operations (network access, system modification)
   
   3. **Check dependencies**:
      - Review install.sh to see what dependencies will be installed
      - Run installed.sh to verify current system status
      - Ensure required tools are safe and necessary
   
   4. **Start with deactivated**:
      - Install plugin but keep it deactivated initially
      - Test in isolated environment if possible
      - Activate only when confident
   ```

3. **Plugin List Output Enhancement**:
   ```
   $ doc.doc.sh list plugins
   
   Built-in Plugins:
     • file (active) - MIME type detection [BUILT-IN]
     • stat (active) - File metadata extraction [BUILT-IN]
   
   Third-Party Plugins:
     • pdf-extract (inactive) - PDF text extraction [THIRD-PARTY]
       Source: https://github.com/example/plugin
       Warning: Review code before activating
   ```

4. **Installation Confirmation**:
   ```
   $ doc.doc.sh install --plugin pdf-extract
   
   ⚠️ WARNING: Installing third-party plugin 'pdf-extract'
   
   Plugins run with your user permissions and can:
   - Access any files you can access
   - Execute system commands
   - Modify your data
   
   This plugin will execute: /bin/bash pdf-extract/main.sh
   
   Have you reviewed the plugin code? (yes/no): _
   ```

#### **Developer Guide: Secure Plugin Development**

Must include:

1. **Security Guidelines**:
   ```markdown
   ## Plugin Security Guidelines
   
   ### Input Validation
   Your plugin receives JSON input via stdin (per ADR-003):
   - **Always** parse and validate JSON input from stdin
   - **Always** validate filePath parameter exists and is readable
   - **Always** check filePath is within expected directory
   - **Never** execute file content without validation
   - **Never** assume filePath format or content
   - **Always** validate input matches descriptor input schema types
   
   ### Output Sanitization
   Your plugin returns JSON via stdout (per ADR-003):
   - **Always** return valid JSON matching descriptor output schema
   - **Always** escape special characters in JSON string values
   - **Always** use proper JSON encoding (use jq or json library)
   - **Never** include raw file content without JSON escaping
   - **Never** include system paths unnecessarily
   - **Never** log sensitive information to stdout (use stderr for logging)
   
   ### Resource Management
   - **Always** implement timeout for long operations
   - **Always** clean up temporary files
   - **Never** consume unbounded memory or disk space
   - **Never** spawn background processes that outlive plugin execution
   
   ### System Interaction
   - **Never** require root/sudo for plugin operation
   - **Never** modify files outside designated plugin data directory
   - **Never** access network unless absolutely necessary (document clearly)
   - **Never** execute user-controllable commands
   - **Always** read input from stdin, write output to stdout
   - **Always** use stderr for error messages and logging
   
   ### Dependencies
   - **Minimize** external tool dependencies
   - **Document** dependencies in install.sh and code comments
   - **Check** dependency availability in installed.sh
   - **Fail gracefully** if dependency missing
   ```

2. **Security Checklist for Plugin Developers**:
   ```markdown
   ## Plugin Security Checklist
   
   Before publishing your plugin:
   
   - [ ] Input validation: JSON input from stdin parsed and validated
   - [ ] Schema compliance: Input matches descriptor input schema
   - [ ] Output validation: JSON output matches descriptor output schema
   - [ ] JSON formatting: Output is valid JSON (use jq or JSON library)
   - [ ] Error handling: Errors to stderr, no sensitive data in messages
   - [ ] Resource limits: Timeouts and cleanup implemented
   - [ ] Dependencies documented: install.sh and installed.sh complete
   - [ ] No hardcoded paths: Works on different systems
   - [ ] No network access: Or clearly documented if necessary
   - [ ] Tested with malicious inputs: Adversarial JSON testing done
   - [ ] Code reviewed: Another developer reviewed for security
   - [ ] Documentation complete: README explains what plugin does
   ```

3. **Anti-Patterns (What NOT to Do)**:
   ```markdown
   ## Plugin Security Anti-Patterns
   
   ### ❌ DON'T: Execute file content
   ```bash
   # VULNERABLE - Executes file content as code
   bash < "$file_path"
   eval "$(cat "$file_path")"
   ```
   
   ### ❌ DON'T: Use unvalidated input
   ```bash
   # VULNERABLE - Unvalidated JSON input
   # Read stdin without validation
   file_path=$(jq -r '.filePath')  # No validation!
   ```
   
   ### ✅ DO: Read and validate JSON input from stdin
   ```bash
   # SAFE - Read JSON from stdin and validate
   input=$(cat)  # Read stdin
   file_path=$(echo "$input" | jq -r '.filePath')
   
   # Validate the parsed value
   if [[ -f "$file_path" ]] && [[ -r "$file_path" ]]; then
       # Process file safely
       result=$(process_file "$file_path")
       # Return JSON to stdout
       jq -n --arg res "$result" '{result: $res}'
   else
       echo "Error: Invalid or unreadable file" >&2
       exit 1
   fi
   ```
   
   ### ❌ DON'T: Return invalid JSON
   ```bash
   # WRONG - Not valid JSON
   echo "result: $value"
   ```
   
   ### ✅ DO: Return valid JSON using jq
   ```bash
   # CORRECT - Valid JSON output
   jq -n --arg val "$value" '{result: $val}'
   ```
   
   ### ❌ DON'T: Log to stdout
   ```bash
   # WRONG - Pollutes JSON output
   echo "Processing file..." 
   jq -n '{result: "done"}'
   ```
   
   ### ✅ DO: Log to stderr
   ```bash
   # CORRECT - Logging to stderr
   echo "Processing file..." >&2
   jq -n '{result: "done"}
   ```
   ```

### Test Requirements

**Documentation Tests**:
- Security sections present in User Guide
- Security sections present in Developer Guide  
- Plugin security warning appears in CLI output
- Plugin source attribution in list output
- Installation confirmation prompt works

**User Experience Tests**:
- First-time users understand plugin risks
- Plugin developers have clear security guidance
- Warning messages are clear and actionable
- Documentation is easy to find and read

### Acceptance Criteria

- [ ] User Guide includes plugin security section
- [ ] Developer Guide includes secure plugin development section
- [ ] CLI warns when installing third-party plugins
- [ ] Plugin list distinguishes built-in vs. third-party
- [ ] Installation requires confirmation for third-party plugins
- [ ] Documentation reviewed for clarity and completeness
- [ ] Users can make informed decisions about plugin trust

### Implementation Notes

**CLI Warning Implementation**:
```bash
install_plugin() {
    local plugin_name="$1"
    local plugin_path="plugins/$plugin_name"
    
    # Check if built-in or third-party
    if is_builtin_plugin "$plugin_name"; then
        log_info "Installing built-in plugin: $plugin_name"
    else
        log_warn "⚠️  Installing THIRD-PARTY plugin: $plugin_name"
        log_warn ""
        log_warn "Third-party plugins run with your user permissions and can:"
        log_warn "  • Access any files you can access"
        log_warn "  • Execute system commands"
        log_warn "  • Modify your data"
        log_warn ""
        log_warn "Plugin command: $(get_plugin_main_command "$plugin_name")"
        log_warn ""
        
        if [[ "$FORCE" != "true" ]]; then
            read -p "Have you reviewed the plugin code? (yes/no): " response
            [[ "$response" == "yes" ]] || {
                log_info "Installation cancelled"
                return 1
            }
        fi
    fi
    
    # Proceed with installation...
}
```

**Plugin List Enhancement**:
```bash
list_plugins() {
    echo "Built-in Plugins:"
    for plugin in "${BUILTIN_PLUGINS[@]}"; do
        local status=$(get_plugin_status "$plugin")
        echo "  • $plugin ($status) [BUILT-IN]"
    done
    
    echo ""
    echo "Third-Party Plugins:"
    for plugin in "${THIRDPARTY_PLUGINS[@]}"; do
        local status=$(get_plugin_status "$plugin")
        local source=$(get_plugin_source "$plugin")
        echo "  • $plugin ($status) [THIRD-PARTY]"
        [[ -n "$source" ]] && echo "    Source: $source"
    done
}
```

### Related Requirements

- REQ_SEC_003 (Plugin Descriptor Validation)
- REQ_SEC_009 (JSON Input Validation) - replaces REQ_SEC_008
- REQ_SEC_008 (Environment Variable Sanitization) - **OBSOLETED**
- REQ_0003 (Plugin-Based Architecture)
- REQ_0004 (Documentation and Help System)

### Risk if Not Implemented

**Risk Level**: MEDIUM (Supporting control for HIGH risk plugin system)

Without security documentation:
- **Users unknowingly install malicious plugins**
- **Plugin developers create insecure plugins unintentionally**
- **Social engineering easier** (users trust all plugins equally)
- **Incident response harder** (users don't know what happened)
- **Reputation damage** (project blamed for plugin security issues)

Documentation is a critical defense layer when technical controls (sandboxing) are not yet implemented. It shifts responsibility to informed user choice.

### Implementation Priority

This requirement should be implemented in MVP alongside plugin system:
1. Basic warning message when installing third-party plugins
2. Plugin security section in README/User Guide
3. Plugin development security guidelines
4. Enhanced plugin list showing built-in vs. third-party

Future enhancements:
- Plugin signing verification
- Plugin security rating system
- Official plugin repository with review process

### References

- Security Concept Section 5.3 (Scope 3: Plugin System)
- Security Concept Section 7.1 (Security Controls)
- Architecture Vision: 08_concepts.md - Plugin Architecture
- CWE-1286: Improper Validation of Syntactic Correctness of Input
- OWASP: Insufficient Security Documentation
