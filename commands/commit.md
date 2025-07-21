## Create well-formatted git commits with conventional commit messages

### Features:

- Runs pre-commit checks by default (lint, build, generate docs)
- Automatically stages files if none are staged
- Uses conventional commit format with descriptive prefixes
- Suggests splitting commits for different concerns

### Usage:

- `/commit` - Standard commit with pre-commit checks
- `/commit #$ARGUMENTS` - Standard commit with pre-commit checks, related to ticket #$ARGUMENTS
- `/commit --no-verify` - Skip pre-commit checks

### Commit Types:

- "FEAT": New features
- "FIX": Bug fixes
- "DOC": Documentation changes
- "REFACTOR": Code restructuring without changing functionality
- "STYLE": Code formatting, missing semicolons, etc.
- "PERF": Performance improvements
- "TEST": Adding or correcting tests
- "CHORE": Tooling, configuration, maintenance
- "DEL": Removing code or files
- "SEC": Security improvements
- "HOTFIX": Critical fixes
- "WIP": Work in progress
- "CHG": General changes to existing code or functionality, i.e. anything that's not the above

### Process:

1. Check for staged changes (`git status`)
2. If no staged changes, review and stage appropriate files
3. Run pre-commit checks (unless --no-verify)
4. Analyze changes to determine commit type
5. Generate descriptive title, prefix with commit type in square brackets ("[TYPE] description"), e.g. "[FEAT] Add new feature" or "[FIX] Fix problems with x, y, z"
6. Generate descriptive commit message
7. Add body for complex changes explaining why
8. Execute commit

### Best Practices:

- Keep commits atomic and focused
- Write in imperative mood ("Add feature" not "Added feature")
- Explain why, not just what
- Reference issues/PRs when relevant
- Split unrelated changes into separate commits
- You MUST NOT include any Claude co-authorship details
- Reference ticket numbers at the end of commit messages, e.g. "Fixes $ARGUMENTS" or "Part of $ARGUMENTS"
