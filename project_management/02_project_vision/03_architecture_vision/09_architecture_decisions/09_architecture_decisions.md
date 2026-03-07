# Architecture Decisions

| Decision ID | Title | Status | Decision |
|-------------|-------|--------|----------|
| [ADR-001](ADR_001_mixed_bash_python_implementation.md) | Mixed Bash and Python Implementation Strategy | DECIDED | Use Bash for CLI orchestration and Python for complex filtering/processing logic |
| [ADR-002](ADR_002_prioritize_tool_reuse.md) | Prioritize Reuse of Existing Tools Over Custom Implementation | DECIDED | Prioritize existing, proven tools and libraries over custom implementations unless existing solutions are demonstrably inadequate |
| [ADR-003](ADR_003_json_plugin_descriptors.md) | JSON-Based Plugin Descriptors with Shell Command Invocation | DECIDED | Use JSON descriptor files with shell command invocation for language-agnostic, loosely-coupled plugin system |
| [ADR-004](ADR_004_plugin_exit_code_strategy.md) | Plugin Exit Code and Failure Handling Strategy | DECIDED | Exit 0 = success; exit 65 (EX_DATAERR) = intentional skip / unsupported input; exit 1 = unexpected failure |