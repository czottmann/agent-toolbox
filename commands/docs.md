## Read SDK and framework documentation, either locally or from context7

### Features:

- Reads documentation either from file system or context7.
- Common libraries are pre-configured as shorthands.

### Usage:

- `/docs help` - List defined docs shorthands
- `/docs <library>` - Get documentation for $ARGUMENTS.

When listing defined docs shorthands, output them as a list, and use the list
item format "<shorthand>: <package name>".

### Fetching docs

If the argument is one of the known shorthands, and relates to a filename, use
Bash:

```bash
cat ~/Code/agent-toolbox/framework-docs/<filename>"
```

If the argument is one of the known shorthands, and relates to a context7
library ID, use Bash:

```bash
curl "https://context7.com/<library-id>/llms.txt?tokens=25000"
```

Otherwise, query context7 MCP's tool with $ARGUMENTS.

### Docs shorthands

| Shorthand   | Package name            | context7 library ID                        | File name                     |
| ----------- | ----------------------- | ------------------------------------------ | ----------------------------- |
| async-algos | swift-async-algorithms  | /apple/swift-async-algorithms              |                               |
| buttonkit   | ButtonKit               |                                            | packages/buttonkit-0.6.md     |
| collections | swift-collections       | /apple/swift-collections                   |                               |
| defaults    | Defaults                |                                            | packages/defaults-8.20.md     |
| grdb        | GRDB                    | /groue/grdb.swift                          |                               |
| sb          | SharedBasics            |                                            | packages/sharedbasics-1.19.md |
| tca         | Composable Architecture | /pointfreeco/swift-composable-architecture |                               |
