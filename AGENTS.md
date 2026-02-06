# Agent Registry

This document catalogs all specialized agents available in this repository. Agents are autonomous task executors that handle complex, multi-step operations within their domains of expertise.

## Available Agents

### [README Maintainer Agent](.github/agents/readme-maintainer.agent.md)
- **Location**: `.github/agents/readme-maintainer.agent.md`
- **Purpose**: Maintains comprehensive, up-to-date README.md documentation
- **Expertise**: Technical documentation, project analysis, setup instructions, contributor guidelines
- **Use When**: 
  - Creating initial project documentation
  - Updating README after feature changes
  - Improving developer onboarding documentation
  - Ensuring documentation accuracy before releases

### [License Governance Agent](.github/agents/license-governance.agent.md)
- **Location**: `.github/agents/license-governance.agent.md`
- **Purpose**: Verifies that project content and dependencies are compatible with the project license
- **Expertise**: License compliance, compatibility analysis, attribution requirements
- **Use When**:
  - Adding or updating dependencies
  - Introducing third-party assets or code
  - Preparing a release or distribution

### [Requirements Engineer Agent](.github/agents/requirements-engineer.agent.md)
- **Location**: `.github/agents/requirements-engineer.agent.md`
- **Purpose**: Analyzes project vision and creates structured requirement records
- **Expertise**: Requirements elicitation, vision analysis, requirement lifecycle management
- **Use When**:
  - Extracting requirements from vision documents
  - Refining and analyzing requirements
  - Moving requirements through acceptance and implementation lifecycle
  - Maintaining traceability between vision and requirements

### [Architect Agent](.github/agents/architect.agent.md)
- **Location**: `.github/agents/architect.agent.md`
- **Purpose**: Reviews architecture visions, maintains architecture documentation, and verifies implementation compliance
- **Expertise**: Software architecture principles, arc42 documentation framework, architecture compliance verification, cross-reference management
- **Use When**:
  - Reviewing architecture vision in `01_vision/03_architecture`
  - Maintaining architecture documentation in `03_documentation/01_architecture`
  - Verifying implementation follows architecture vision
  - Documenting architectural decisions and deviations
  - Keeping architecture documentation synchronized with implementation
  - Conducting architecture compliance audits

---

## How to Use Agents

Copilot automatically selects and invokes agents based on task requirements. To explicitly request an agent, mention it by name or tag (e.g., `#readme-maintainer`).

## Creating New Agents

Follow the template in [copilot-instructions.md](.github/copilot-instructions.md#agent-definition-template) to create new agents. All agents should:
1. Have a clear, focused purpose
2. Define their expertise boundaries
3. Specify input/output formats
4. Include example usage scenarios

## Agent Maintenance

- **Review Schedule**: Quarterly review of agent effectiveness
- **Updates**: Document agent improvements in their respective `.agent.md` files
- **Deprecation**: Mark unused agents clearly before removal
- **Registry**: Keep this file synchronized with actual agent files
