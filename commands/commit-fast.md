# Streamlined git commit

Generate 3 commit message suggestions based on the staged changes, then automatically use the first suggestion without user confirmation.

Follow conventional commit format (see @./commit.md) with appropriate title and create descriptive messages that explain the purpose of changes. Skip the manual message selection step to streamline the commit process.

## Steps:
1. Run `git status` to see staged changes
2. Generate 3 commit message suggestions following conventional commit format
3. Automatically select the first suggestion
4. Execute `git commit -m` with the selected message
5. Exclude Claude co-authorship footer from commits

## Commit Types:
- "FEAT": New features
- "FIX": Bug fixes
- "DOC": Documentation changes
- "REFACTOR": Code restructuring without changing functionality
- "STYLE": Code formatting, missing semicolons, etc.
- "PERF": Performance improvements
- "TEST": Adding or correcting tests
- "CHORE": Tooling, configuration, maintenance
- "WIP": Work in progress
- "DEL": Removing code or files
- "HOTFIX": Critical fixes
- "SEC": Security improvements
