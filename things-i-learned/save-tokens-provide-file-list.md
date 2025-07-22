## Save tokens by providing the list of project files right off the bat

Me: "Check file xyz.swift and tell me what's wrong" (file is in a folder two levels down)

Claude: attempts to open `./xyz.swift`, fails, starts searching for the project folder

This isn't efficient, and can be prevented by providing a static list of files as part of the `CLAUDE.md`. First, I added these lines to the end of the project's `CLAUDE.md`:

    ## Files In This Project

    @./.claude/tmp/project-files.md

Then, I generate the list of files which I write to the referenced file before launching `claude`. Because I don't like repeating myself, I wrote a wrapper for that, see [claude-wrapper](../bin/claude-wrapper).
