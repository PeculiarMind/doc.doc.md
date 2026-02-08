# ADR-0006: No Agent System in Product Architecture

**ID**: ADR-0006  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08

## Context

Project uses 6 agents (Developer, Tester, Architect, Requirements Engineer, Security, License Governance) for development workflow. Need to determine whether agent system belongs in product architecture documentation.

## Decision

Agent system is a **development process tool** for building doc.doc, not a feature of doc.doc itself. Agent architecture does NOT belong in product architecture documentation.

## Rationale

**Separation of Concerns**:
- **Product**: doc.doc.sh toolkit for file analysis
- **Process**: Agent-driven TDD workflow for developing doc.doc

**Product Architecture**:
- Documents **what we're building** (doc.doc toolkit)
- Covers CLI, plugins, orchestration, reporting
- Users run doc.doc, not agents

**Development Process**:
- Documents **how we build it** (agent workflow)
- Covers Developer→Tester→Architect coordination
- Contributors interact with agents, users don't

**Why This Matters**:

If we included agents in product architecture:
- ❌ Confuses users (they don't use agents)
- ❌ Mixes process with product
- ❌ Bloats architecture documentation
- ❌ Implies agents are runtime components

Keeping them separate:
- ✅ Clear focus: Architecture documents the product
- ✅ Process documented elsewhere (.github/agents/)
- ✅ Users understand doc.doc, contributors understand workflow
- ✅ Architecture remains relevant to end users

## Alternatives Considered

### Include Agent System in Architecture
- ❌ Confuses end users
- ❌ Mixes development tools with product features
- ❌ Makes architecture documentation harder to navigate
- **Decision**: Violates separation of concerns

### Document Agents in Separate Architecture Section
- ✅ Keeps architecture centralized
- ❌ Still implies agents are part of product
- ❌ Bloats product documentation
- **Decision**: Process documentation belongs in .github/ not architecture/

### No Documentation of Agent System
- ❌ Contributors wouldn't understand workflow
- ❌ Process knowledge lost
- **Decision**: Must document, but in appropriate location

## Consequences

### Positive
- Architecture documentation focused on product
- Clear boundary: product vs development process
- Agent system can evolve without affecting product architecture
- Users not exposed to internal development tools

### Negative
- Contributors must look in multiple places (architecture + .github/)
- Might need to explain separation to new contributors

### Risks
- Contributors might mistakenly add agent references to product docs
- Process improvements might not be reflected in architecture

## Implementation Notes

**Where Agent System IS Documented**:
- `AGENTS.md` - Agent registry and overview
- `.github/agents/*.agent.md` - Individual agent definitions
- `.github/copilot-instructions.md` - Agent coordination and usage
- `02_agile_board/` - Development workflow states

**NOT Documented in Product Architecture**:
- `01_vision/03_architecture/` - Product architecture only
- `03_documentation/01_architecture/` - Implemented product architecture only

**Documentation Guideline**:
- Product features → Architecture documentation
- Development tools/process → .github/ and AGENTS.md

## Related Items

- See `AGENTS.md` for agent system documentation
- See `.github/copilot-instructions.md` for agent coordination

**Trade-offs Accepted**:
- **Product Focus over Process Documentation**: Architecture documents user-facing system
- **Clarity over Completeness**: Omit development tools from product architecture
- **Documentation Distribution over Centralization**: Accept separation for better organization
