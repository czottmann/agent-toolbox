# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal development toolbox containing:
- **Project Rules**: Structured workflow templates in `project-rules/` for common development tasks
- **Custom Commands**: Claude slash commands in `commands/` for specific workflows
- **CLI Utilities**: Fish shell scripts in `bin/` for development automation

The toolbox follows a template-driven approach where each workflow is documented as structured markdown files that guide Claude through specific development processes.

## Key Commands

### Development Utilities
- `./setup-symlinks-from-bin.fish` - Interactive script to create/remove symlinks from `bin/` to `/usr/local/bin/`
- `./setup-claude-mcp-servers.fish` - Install MCP servers for Claude (currently Linear)
- `xcodebuild-wrapper` - Filtered Xcode build output (errors on failure, last 30 lines on success)
- `claude-wrapper` - Creates file list in `.claude/tmp/` before launching Claude

### Custom Slash Commands
- `/commit` - Conventional commits with pre-commit checks and ticket integration
- `/commit-fast` - Streamlined commit with automatic message selection  
- `/add-to-changelog <version> <change_type> <message>` - Update CHANGELOG.md following Keep a Changelog format

## Architecture

### Project Rules (`project-rules/`)
Template-driven workflow files that provide structured guidance:

- **analyze-issue.md** - Linear issue analysis with technical specification generation
- **implement-task.md** - Methodical task implementation with strategy evaluation
- **bug-fix.md** - Complete bug fix workflow from issue creation to PR
- **check.md** - Code quality and security checks (`npm run check`)
- **clean.md** - Codebase formatting and linting fixes
- **pr-review.md** - Multi-perspective pull request reviews (PM, Dev, QA, Security, DevOps, UX)

### Custom Commands (`commands/`)
Claude slash command definitions for specific workflows with parameter handling.

### CLI Tools (`bin/`)
Fish shell utilities for development automation and build process enhancement.

## Development Workflow

### For New Project Rules
1. Follow template in `create-command.md`
2. Include structured sections: Purpose, Process, Examples, Notes
3. Use action-oriented naming and clear parameter definitions

### For Xcode Projects
- Use `xcodebuild-wrapper` instead of direct `xcodebuild` for cleaner output
- Wrapper automatically filters success/failure output appropriately

### For Git Workflows
- Leverage `/commit` and `/commit-fast` commands for consistent conventional commits
- Commands handle staging, pre-commit checks, and ticket references automatically

### Linear Integration
- Install Linear MCP server using `setup-claude-mcp-servers.fish`
- Use ticket format "ZCO-<number>" for issue references
- Apply `analyze-issue.md` workflow for comprehensive issue analysis

## Key Conventions

- Fish shell preferred over bash for new scripts
- Ripgrep (`rg`) preferred over `grep`
- `sd` preferred over `sed` for text replacement
- All project rules follow structured markdown templates
- Slash commands include parameter validation and examples
- CLI tools provide interactive interfaces using `gum` when appropriate