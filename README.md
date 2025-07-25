# agent-toolbox

This repo contains files for setting up Claude Code ("CC") for local development (which is mostly Xcode work). It contains rules which can be `@`-imported from a `CLAUDE.md` file, custom slash commands for CC, as well as scripts for setting up wrapper scripts (which are described below).

As a bonus, [a few things I learned along the way](things-i-learned/).


## Framework & SDK documentation

See [framework-docs/](framework-docs/). I load them manually when they are helpful.

I added their local directory path to `~/.claude/settings.json`'s `additionalDirectories` array so there's no extra permissions request.


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

    ## Files In This Project
    @./.claude/tmp/project-files.md


### gemini-wrapper

A wrapper around `gemini` which utilizes [czottmann/render-claude-context](https://github.com/czottmann/render-claude-context) to make Gemini "inherit" CC's context. Adds the list of project files to the output as well.

#### Usage

If you want to use it from the command line, run `gemini-wrapper` instead of `gemini`.

#### What it does

It collects `CLAUDE.md` files from the directory hierarchy (project folder up to `~/.claude/`), embeds their `@`-imports and commands, and generates processed context files with resolved imports that are used as context for Gemini. Those are stored right next to the found `CLAUDE.md` files, while the global file is saved to `~/.gemini/`.

#### Setup

See [render-claude-context's README.md](https://github.com/czottmann/render-claude-context?tab=readme-ov-file#example):

```bash
render-claude-context setup
```

In your global (or project) `CLAUDE.md`, `@`-import the [`gemini.md` rule](project-rules/gemini.md), e.g.

```
@/Users/morty/agent-toolbox/project-rules/gemini.md
```

### opencode-wrapper

A wrapper around `opencode` which utilizes [czottmann/render-claude-context](https://github.com/czottmann/render-claude-context) to create `AGENTS.md` from CC's context. Adds the list of project files to the output as well.

🚨 It operates in <abbr title="zero fucks given">0FG</abbr> mode and **will overwrite any existing `AGENTS.md` file it finds in the directory hierarchy.**

#### Usage

If you want to use it from the command line, run `opencode-wrapper` instead of `opencode`.

#### What it does

It collects `CLAUDE.md` files from the directory hierarchy (project folder up to `~/.claude/`), embeds their `@`-imports and commands, and generates processed context files with resolved imports that are used as context for opencode. Those are stored right next to the found `CLAUDE.md` files, while the global file is saved to `~/.config/opencode/`.

#### Setup

No setup necessary.

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

See [project-rules](project-rules). These are `@`-imported one-by-one in my global `CLAUDE.md`.


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

Optional, if you want to use Google Gemini or opencode as a tool and **have them use CC's context** (see above):

- [render-claude-context](https://github.com/czottmann/render-claude-context)


## Author

Carlo Zottmann, <carlo@zottmann.dev>, https://c.zottmann.dev, https://github.com/czottmann

> ### 💡 Did you know?
>
> I make Shortcuts-related macOS & iOS productivity apps like [Actions For Obsidian](https://actions.work/actions-for-obsidian), [Browser Actions](https://actions.work/browser-actions) (which adds Shortcuts support for several major browsers), and [BarCuts](https://actions.work/barcuts) (a surprisingly useful contextual Shortcuts launcher). Check them out!


## Acknowledgements

Most rules and ideas have been looted partially or wholesale from [steipete/agent-rules: Rules and Knowledge to work better with agents such as Claude Code or Cursor](https://github.com/steipete/agent-rules). Thanks for the inspiration and knowledge sharing, Peter! 🙏🏼

What I took, I've cleaned up for readability and adjusted to my liking.
