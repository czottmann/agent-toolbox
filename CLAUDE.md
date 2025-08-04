# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal development toolbox containing:
- **Global & Project Rules**: Structured workflow templates in `rules/` for common development tasks
- **Custom Commands**: Claude slash commands in `commands/` for specific workflows
- **CLI Utilities**: Fish shell scripts in `bin/` for development automation

The toolbox follows a template-driven approach where each workflow is documented as structured markdown files that guide Claude through specific development processes.

## Key Commands

### Setup Commands
- `./setup-setup-bin-symlinks.fish` - Interactive script to create/remove symlinks from `bin/` to `/usr/local/bin/`
- `./setup-mcp-servers.fish` - Install MCP servers for Claude (Linear and Sentry)

### Development Utilities
- `claude-wrapper` - Creates file list in `.claude/tmp/project-files.md` before launching Claude
- `xcodebuild-wrapper` - Filtered Xcode build output (errors on failure, last 30 lines on success)

### Custom Slash Commands
- `/commit [#ticket-number]` - Conventional commits with pre-commit checks and optional ticket integration
- `/commit --no-verify` - Skip pre-commit checks
- `/commit-fast` - Streamlined commit with automatic message selection
- `/add-to-changelog <version> <change_type> <message>` - Update CHANGELOG.md following Keep a Changelog format

### Commit Types (for `/commit` and `/commit-fast`)
FEAT, FIX, DOC, REFACTOR, STYLE, PERF, TEST, CHORE, DEL, SEC, HOTFIX, WIP, CHG

## Architecture

### Rules (`rules/`)
Template-driven workflow files that provide structured guidance:

- **analyze-issue.md** - Linear issue analysis with technical specification generation
- **bug-fix.md** - Complete bug fix workflow from issue creation to PR
- **check.md** - Code quality and security checks (`npm run check`)
- **clean.md** - Codebase formatting and linting fixes
- **code-analysis.md** - Advanced code analysis with multiple inspection options
- **context-prime.md** - Prime Claude with comprehensive project understanding
- **create-command.md** - Guide for creating new custom Claude commands
- **create-docs.md** - Create comprehensive documentation for components/features
- **five.md** - "Five Whys" root cause analysis technique
- **gemini.md** - Using Gemini CLI for large codebase analysis
- **git-commits.md** - Conventional commit format and workflow guidelines
- **implement-task.md** - Methodical task implementation with strategy evaluation
- **linear.md** - Linear ticketing and project management integration
- **mermaid.md** - Generate Mermaid diagrams for visualizing code structure
- **modern-swift.md** - Modern SwiftUI development guidelines
- **pr-review.md** - Multi-perspective pull request reviews (PM, Dev, QA, Security, DevOps, UX)
- **preferred-cli-tools.md** - Preferred CLI tools (rg, sd, fish)
- **swift-styleguide.md** - Swift code style and formatting rules
- **update-docs.md** - Generate LLM-optimized documentation
- **xcode-builds.md** - Use `xcodebuild-wrapper` for Xcode projects

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
- Install Linear MCP server using `setup-mcp-servers.fish`
- Use ticket format "ZCO-<number>" for issue references
- Apply `analyze-issue.md` workflow for comprehensive issue analysis

## Key Conventions

- Fish shell preferred over bash for new scripts
- Ripgrep (`rg`) preferred over `grep`
- `sd` preferred over `sed` for text replacement
- All project rules follow structured markdown templates
- Slash commands include parameter validation and examples
- CLI tools provide interactive interfaces using `gum` when appropriate

## Requirements

- Fish shell (https://fishshell.com)
- gum (https://github.com/charmbracelet/gum) for interactive interfaces
- ripgrep (https://github.com/BurntSushi/ripgrep) for fast text search
- fd (file finder) used by `claude-wrapper`

## Using claude-wrapper

To enable file list priming in projects, add this to the project's CLAUDE.md:

    ```markdown
    ## Files In This Project
    @./.claude/tmp/project-files.md

    ```

## MCP Servers

Supported MCP servers (install via `./setup-mcp-servers.fish`):
- **Linear MCP** - Issue tracking and project management integration
- **Sentry MCP** - Error monitoring and debugging integration


## Files In This Project

@./.claude/tmp/project-files.md
