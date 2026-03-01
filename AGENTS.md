# Agent Registry

This document catalogs all specialized agents available in this repository. Agents are autonomous task executors that handle complex, multi-step operations within their domains of expertise.

## Available Agents

| Agent | Location | Purpose |
|-------|----------|---------|
| **architect** | `.github/agents/architect.agent.md` | Maintains architecture vision and documentation, ensures implementation compliance |
| **developer** | `.github/agents/developer.agent.md` | Implements backlog items end-to-end, coordinating tests and quality gates |
| **documentation** | `.github/agents/documentation.agent.md` | Keeps README.md accurate and concise for users and contributors |
| **license** | `.github/agents/license.agent.md` | Audits changes for license compatibility and attribution requirements |
| **product_owner** | `.github/agents/product_owner.agent.md` | Manages product backlog, prioritizes work items, and makes product decisions |
| **requirements** | `.github/agents/requirements.agent.md` | Extracts requirements from vision documents and manages requirement lifecycle |
| **security** | `.github/agents/security.agent.md` | Reviews concepts, tests, and implementations for security risks |
| **tester** | `.github/agents/tester.agent.md` | Creates and executes tests for features, supporting TDD and quality gates |

## Supporting Standards

| File | Location | Purpose |
|------|----------|---------|
| **communication-standards** | `project_management/01_guidelines/agent_behavior/communication_standards.md` | Communication tone and style requirements for all agents |
| **documentation-standards** | `project_management/01_guidelines/documentation_standards/documentation-standards.md` | Documentation conventions and document type registry |
| **agent-template** | `project_management/01_guidelines/documentation_standards/doc_templates/agent_template.md` | Template for defining new agent personas |

## Workflows

| Workflow | Location | Purpose |
|----------|----------|---------|
| **requirements-engineering** | `project_management/01_guidelines/workflows/requirements_engineering_workflow.md` | Requirements derivation and lifecycle management process |
| **implementation** | `project_management/01_guidelines/workflows/implementation_workflow.md` | Feature implementation and quality gate workflow |
