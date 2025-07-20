# agent-toolbox

This repo contains files for setting up Claude Code ("CC") for local development (which is mostly Xcode work). It contains rules which can be `@`-imported from a `CLAUDE.md` file, custom slash commands for CC, as well as scripts for setting up wrapper scripts (which are described below).


## Wrappers

These can be found in `bin/`. They are meant to by symlinked from `/usr/local/bin/`.

The linking is done by running `./setup-bin-symlinks.fish`.

### claude-wrapper

A simple wrapper which primes CC with a list of all files in the current directory. This information prevents a ton of _"Let me find that file"_ steps, thus speeding things up and saving tokens.

#### Usage

Call it instead of `claude`.

#### What it does

It generates the list, writes it to `./.claude/tmp/project-files.md`, calls `claude`, and removes the temp file once CC quits.

#### Setup

To make this work, add this import to your project's `CLAUDE.md` file:

```markdown
## File list / directory layout
@./.claude/tmp/project-files.md
```


### gemini-wrapper

A wrapper around `gemini` which utilizes [czottmann/claude-context-render](https://github.com/czottmann/claude-context-render) which makes Gemini "inherit" CC's context.

#### Usage

If you want to use it from the command line, run `gemini-wrapper` instead of `gemini`.

#### What it does

It collects `CLAUDE.md` files from the directory hierarchy (project folder up to `~/.claude/`), embeds their `@`-imports, and generates processed context files with resolved imports that are used as context for Gemini.

#### Setup

See [claude-context-render's README.md](https://github.com/czottmann/claude-context-render?tab=readme-ov-file#example):

```bash
claude-context-render setup
```

In your global (or project) `CLAUDE.md`, `@`-import the [`gemini.md` rule](project-rules/gemini.md), e.g.

```
@/Users/morty/agent-toolbox/project-rules/gemini.md
```

### xcodebuild-wrapper

A wafer-thin wrapper around `xcodebuild` which saves tokens by outputting only what's necessary.

#### What it does

It transparently hands over any arguments to `xcodebuild`. The difference to calling `xcodebuild` directly is that …

- **on success** it only returns the last 30 lines out output
- **on failure** it greps the output for _"error:"_ and only returns the found lines (uses `rg` with a context of 5 lines)

### Setup

In your global (or project) `CLAUDE.md`, `@`-import the [`xcode-builds.md` rule](project-rules/xcode-builds.md), e.g.

```
@/Users/morty/agent-toolbox/project-rules/xcode-builds.md
```

## Project rules

TODO


## Global commands

Custom slash commands for CC are stored in `./commands/`. They are installed globally by symlinking `./commands/` to `~/.claude/commands`.

Set them up by running `./setup-global-commands.fish`.


## MCP server setup

There are very few MCP servers that I use, namely [Linear MCP](https://linear.app/changelog/2025-05-01-mcp) and [Sentry](https://docs.sentry.io/product/sentry-mcp/).

Set them up by running `./setup-mcp-servers.fish`.


## Requirements

This is an opinionated setup as I'm scratching my own itches here. I'm not aiming for maximum compatibility with everyone and their setups.

- [Fish shell](https://fishshell.com)
- [gum](https://github.com/charmbracelet/gum)
- [ripgrep](https://github.com/BurntSushi/ripgrep)

Optional, if you want to use Google Gemini as a tool and **have it use CC's context** (see above):

- [claude-context-render](https://github.com/czottmann/claude-context-render)


## Author

Carlo Zottmann, <carlo@zottmann.dev>, https://c.zottmann.dev, https://github.com/czottmann

> ### 💡 Did you know?
>
> I make Shortcuts-related macOS & iOS productivity apps like [Actions For Obsidian](https://actions.work/actions-for-obsidian), [Browser Actions](https://actions.work/browser-actions) (which adds Shortcuts support for several major browsers), and [BarCuts](https://actions.work/barcuts) (a surprisingly useful contextual Shortcuts launcher). Check them out!


## Acknowledgements

Most rules and ideas have been looted partially or wholesale from [steipete/agent-rules: Rules and Knowledge to work better with agents such as Claude Code or Cursor](https://github.com/steipete/agent-rules). Thanks for the inspiration and knowledge sharing, Peter! 🙏🏼

What I took, I've cleaned up for readability and adjusted to my liking.
