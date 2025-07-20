# agent-toolbox

This repo contains files for setting up Claude Code ("CC") for local development (which is mostly Xcode work). It contains rules which can be `@`-imported from a `CLAUDE.md` file, as well as scripts for setting up wrapper scripts (which are described below).

## Wrappers

These can be found in `bin/`. They are meant to by symlinked from `/usr/local/bin/`. The linking can be done by running `./setup-symlinks-from-bin.fish`.

### `claude-wrapper`

A simple wrapper which primes CC with a list of all files in the current directory. This information prevents a ton of _"Let me find that file"_ steps, speeding up things and saving tokens.

#### Usage

Call it instead of `claude`.

#### What it does

It generates the list, writes it to `./.claude/tmp/project-files.txt`, calls `claude`, and removes the temp file once CC quits.

#### Setup

To make this work, add this import to your project's `CLAUDE.md` file:

```markdown
## File list / directory layout
@./.claude/tmp/project-files.txt
```

### `xcodebuild-wrapper`

A wafer-thin wrapper around `xcodebuild` which saves tokens by outputting only what's necessary.

#### What it does

It transparently hands over any arguments to `xcodebuild`. The difference to calling `xcodebuild` directly is that …

- **on success** it only returns the last 30 lines out output
- **on failure** it greps the output for _"error:"_ and only returns the found lines (uses `rg` with a context of 5 lines)

### Setup

In your global (or project) `CLAUDE.md`, `@`-import the `project-rules/xcode-builds.md`, e.g.

```
@/Users/morty/agent-toolbox/project-rules/xcode-builds.md
```

## Requirements

This is an opinionated setup as I'm scratching my own itches here. I'm not aiming for maximum compatibility with everyone and their setups.

- [Fish shell](https://fishshell.com)
- [gum](https://github.com/charmbracelet/gum)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
