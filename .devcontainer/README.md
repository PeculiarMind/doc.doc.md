# Development Container Configuration

This devcontainer is configured with Ubuntu 24.04 LTS and includes tools optimized for working with the ProTemp project template.

## Container Structure

- **Dockerfile** - Custom Ubuntu 24.04 LTS container definition
- **devcontainer.json** - VS Code devcontainer configuration

## Included Tools

### Core Development
- **Git** - Version control
- **GitHub CLI** - GitHub integration from the command line
- **Bash** - Default shell

### Runtime Environments
- **Node.js LTS** - For any JavaScript/TypeScript tooling
- **Python (latest)** - For scripting and automation

## Usage

### Opening in VS Code
1. Install the "Dev Containers" extension in VS Code
2. Open the command palette (F1 or Ctrl+Shift+P)
3. Select "Dev Containers: Reopen in Container"

### Rebuilding the Container
If you modify the devcontainer configuration:
1. Open command palette
2. Select "Dev Containers: Rebuild Container"

## Configuration Details

- **Base Image**: Ubuntu 24.04 LTS
- **Default User**: vscode (non-root)
- **Default Shell**: Bash
- **Line Endings**: LF (Unix-style)
- **Tab Size**: 2 spaces
