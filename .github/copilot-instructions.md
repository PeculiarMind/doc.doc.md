# Copilot Instructions

## Agent Discovery

Resolve agents in this priority order:
1. `/*.agent.md` — project-specific agents (highest priority)
2. `.github/agents/*.agent.md` — standard personas
3. `AGENTS.md` — registry and index

Read the agent's `.agent.md` file before delegating. If multiple agents match, use the most specific one.

## Delegation

When using `runSubagent`, provide:
- Task description and specific deliverables
- Relevant file paths and constraints
- What to return in the final report

## Fallback

No matching agent — execute directly. For recurring tasks, propose creating a new agent using the template at `project_management/01_guidelines/documentation_standards/doc_templates/agent_template.md` and update `AGENTS.md`.

## Error Handling

- **Agent failure**: retry with refined instructions, or execute directly and report to user.
- **Scope violation**: explain the limitation and suggest an alternative agent or direct approach.

## Skills

Domain knowledge is packaged as skills under `.github/skills/`:

| Skill | When to load |
|-------|-------------|
| `communication-standards` | Any agent writing output or documentation |
| `documentation-standards` | Creating or updating any project document |
| `implementation-workflow` | Running a feature from backlog to PR |
| `requirements-workflow` | Deriving or managing requirements |
| `architecture-documentation` | Authoring ADRs, IDRs, DEBTRs, Arc42 sections |