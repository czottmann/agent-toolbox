## Context Prime

Prime Claude with comprehensive project understanding.

### Standard Context Loading:

1. Read README.md for project overview
2. If it exists, read the documentation in `docs/`
3. Read CLAUDE.md for AI-specific instructions
4. Unless CLAUDE.md didn't contain a list of project files, generate a list excluding ignored paths
6. Review key configuration files
7. Understand project structure and conventions

### Steps:

1. **Project Overview**:
   - Read README.md
   - Identify project type and purpose
   - Note key technologies and dependencies

2. **AI Guidelines**:
   - Read CLAUDE.md if present
   - Load project-specific AI instructions
   - Note coding standards and preferences

3. **Repository Structure**:
   - Run: `git ls-files | head -50` for initial structure
   - Identify main directories and their purposes
   - Note naming conventions

4. **Configuration Review**:
   - Package manager files (package.json, Cargo.toml, etc.)
   - Build configuration
   - Environment setup

5. **Development Context**:
   - Identify test framework
   - Note CI/CD configuration
   - Review contribution guidelines

### Advanced Options:

- Load specific subsystem context
- Focus on particular technology stack
- Include recent commit history
- Load custom command definitions

### Output:

Establish clear understanding of:

- Project goals and constraints
- Technical architecture
- Development workflow
- Collaboration parameters
