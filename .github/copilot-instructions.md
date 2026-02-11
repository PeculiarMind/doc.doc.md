# Co-Pilot Instructions

## Overview
This document defines the guidelines for utilizing specialized agents within this repository to accomplish complex, multi-step tasks efficiently. Copilot must proactively identify when agent delegation is appropriate and execute task routing according to the agent hierarchy defined below.

## Agent System Architecture

### How Agents Work
- **Agent invocation**: Use the `runSubagent` tool to delegate tasks to specialized agents
- **Agent definition files**: Agents are defined in `*.agent.md` files containing their purpose, expertise, and limitations
- **Stateless execution**: Each agent invocation is independent; agents return a final report after completion
- **Asynchronous processing**: Agents work autonomously without requiring intermediate user interaction

## Agent Discovery and Priority

### 1. **Identify Agent Availability**
Before executing any complex task (requiring 3+ steps or specialized domain knowledge), search for applicable agents in this priority order:

   1. **Root directory** (`/*.agent.md`): Highest priority, project-specific agents
   2. **Agent directory** (`.github/agents/*.agent.md`): Standard agent personas
   3. **Agent registry** (`AGENTS.md`): Central index of all available agents (if exists)

### 2. **Task Complexity Assessment**
Determine if agent delegation is appropriate:

   **Use an agent when:**
   - Task requires 5+ distinct steps
   - Specialized domain expertise needed (e.g., security, testing, documentation)
   - Multiple files/directories need coordinated changes
   - Research or exploration required before implementation
   - User explicitly mentions or tags an agent (e.g., `#security-agent`)

   **Handle directly when:**
   - No matching agent expertise available

### 3. **Agent Selection Process**
   - Read the `*.agent.md` file to understand agent capabilities and limitations
   - Match task requirements against agent expertise
   - Verify task falls within agent's defined scope
   - If multiple agents match, select the most specific one

### 4. **Task Delegation Execution**
When delegating to an agent:
   
   ```
   Use runSubagent with:
   - Clear, detailed task description
   - Specific deliverables expected
   - Relevant context (file paths, requirements, constraints)
   - Explicit instructions on what to return in the final report
   ```

   **Example invocation:**
   ```
   Task: "Review all authentication code in src/auth/ for security vulnerabilities"
   Agent: security-review.agent.md
   Expected return: List of vulnerabilities with severity ratings and fix recommendations
   ```

### 5. **Fallback Strategy**
If no suitable agent exists:
   
   - **For critical/recurring tasks**: Propose creating a new agent
   - **For one-off tasks**: Execute directly but offer to create an agent for future use
   - **When proposing new agents**: Ask user to define:
     - Agent name and primary expertise
     - Scope and limitations
     - Expected input/output formats
     - Success criteria

### 6. **Documentation Requirements**
When creating or modifying agents:
   
   - **Agent definition file** (`<name>.agent.md`) must include:
     - **Purpose**: One-sentence description
     - **Expertise**: Specific domains/technologies
     - **Responsibilities**: What tasks it handles
     - **Limitations**: What it should NOT do
     - **Input requirements**: What context it needs
     - **Output format**: What it returns
   
   - **Update agent registry** (`AGENTS.md`): Add entry with name, location, and brief description
   
   - **Version control**: Commit agent changes with clear descriptions

## Error Handling

- **Agent failure**: If agent returns an error or incomplete result, analyze the failure and either:
  - Retry with refined instructions
  - Execute task directly
  - Report issue to user with specific error details

- **Missing agent**: If referenced agent file doesn't exist, inform user and offer to create it or proceed without

- **Scope violations**: If user requests task outside agent's defined scope, explain limitation and suggest alternative approach

## Agent Definition Template

When creating new agents, use this template structure:

```markdown
# [Agent Name]

## Purpose
One-sentence description of the agent's primary function.

## Expertise
- Domain 1
- Technology 2
- Specific skill 3

## Responsibilities
- Task type 1 it handles
- Task type 2 it handles

## Limitations
- What it should NOT do
- Out-of-scope activities

## Input Requirements
- Required context
- Expected parameters

## Output Format
- What the agent returns
- Structure of final report

## Example Usage
Brief example of when to invoke this agent.
```

## Best Practices

1. **Prefer agent delegation** for complex tasks over manual execution
2. **Read agent definitions** completely before delegating
3. **Provide comprehensive context** to agents - they cannot ask follow-up questions
4. **Trust agent outputs** - they are specialized for their domains
5. **Document new patterns** - if you repeatedly handle similar tasks, suggest creating an agent
6. **Maintain agent registry** - keep `AGENTS.md` updated as single source of truth

By following these instructions, Copilot ensures efficient task routing, maintains consistency, and leverages specialized expertise for optimal results.