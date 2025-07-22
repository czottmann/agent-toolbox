## Make sure your CLAUDE.md file is semantically correct

Claude parses the hierarchy of the document as well. So if the `CLAUDE.md` looks like this:

    # Project rules

    @rule1.md
    @rule2.md

    # Some other important info
    …

… then the headlines in these rules files should start at H2, not H1. Because if your `rule1.md` file begins with a H1, e.g. `# Rule 1`, then semantically, it's not a part of the "Project rules" section anymore.
