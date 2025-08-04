## Git commit message format

When asked to commit, do…

- Automatically stage files if none are staged
- Use conventional commit format with descriptive prefixes
- Suggest splitting commits for different concerns

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

1. Analyze changes to determine commit type
2. Generate descriptive title, prefix with commit type in square brackets ("[TYPE] description"), e.g. "[FEAT] Add new feature" or "[FIX] Fix problems with x, y, z"
3. Generate descriptive commit message
4. Add body for complex changes explaining why
5. Execute commit

### Best Practices:

- Keep commits atomic and focused
- Write in imperative mood ("Add feature" not "Added feature")
- Explain why, not just what
- Split unrelated changes into separate commits
- Reference issues/ PRs/ ticket numbers at the end of commit messages, e.g. "Fixes <ticket-id>" or "Part of <ticket-id>"
- You MUST NOT include any co-authorship details unless explicitly instructed to
