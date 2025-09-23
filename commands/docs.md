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
library ID, you MUST use Bash to fetch the docs:

```bash
curl "https://context7.com/<library-id>/llms.txt?tokens=25000"
```

If the argument is one of the known shorthands, and relates to one or more URL, you MUST use curl via Bash tool to fetch the docs.

If the argument relates to a context7 library ID but it is not one of the known shorthands, or if its Bash call wasn't successful, query context7 MCP's tool with $ARGUMENTS.

When you're done reading the docs, wait for further instructions.

### Docs shorthands

| Shorthand      | Package name            | context7 library ID                        | File name                      | URL                                                                                      | Notes                               |
| -------------- | ----------------------- | ------------------------------------------ | ------------------------------ | ---------------------------------------------------------------------------------------- | ----------------------------------- |
| async-algos    | swift-async-algorithms  | /apple/swift-async-algorithms              |                                |                                                                                          |                                     |
| buttonkit      | ButtonKit               |                                            | packages/buttonkit-0.6.md      |                                                                                          |                                     |
| collections    | swift-collections       | /apple/swift-collections                   |                                |                                                                                          |                                     |
| defaults       | Defaults                |                                            | packages/defaults-8.20.md      |                                                                                          |                                     |
| grdb           | GRDB                    | /groue/grdb.swift                          |                                |                                                                                          |                                     |
| networking     | freshOS/Networking      |                                            | packages/sharedbasics-1.19.md  |                                                                                          |                                     |
| perception     | Perception              |                                            |                                | https://raw.githubusercontent.com/pointfreeco/swift-perception/refs/heads/main/README.md |                                     |
| sb             | SharedBasics            |                                            | packages/sharedbasics-1.19.md  |                                                                                          |                                     |
| simplekeychain | auth0/SimpleKeychain    |                                            | packages/simplekeychain-1.3.md |                                                                                          |                                     |
| tca            | Composable Architecture | /pointfreeco/swift-composable-architecture |                                |                                                                                          | Uses Perception package internally. |
