# Things I've learned (the hard way)

Just some lessons I picked up along the way. They work for me, YMMV. I'm learning all the time, and all of this might be obvious to you already.


## Make sure your rules are syntactically correct

Modularizing the [project rules](project-rules/) is a good idea, but it's also a good idea to _ensure_ that Claude can read them correctly.

Case in point: One of the rules contained a code block that contained code blocks, like this:

<pre><code>```markdown
# Something something

```bash
```
```</code></pre>

As a human, I could comprehend it, but a Markdown parser can't. Claude read _everything_ below that point as being part of a code block, basically ignoring it. I only noticed that something was off because one of the rules that were `@`-imported below it weren't followed.

It took me a while to find the Markdown issue but it became clear once I rendered Claude's context out into a separate file (using [render-claude-context](https://github.com/czottmann/render-claude-context)), and skimmed it using [glow](https://github.com/charmbracelet/glow) (another Markdown rendered would've worked, too):

```bash
cd my-project-folder

# Generates a resolved & rendered CLAUDE.md copy ("CLAUDE-derived.md"), starting
# in project folder, up to ~/
render-claude-context create

# Read the local file, repeat this step up the directory tree as necessary
glow CLAUDE-derived.md

# Removed the rendered files again
render-claude-context cleanup
```


## Make sure your CLAUDE.md file is semantically correct

Claude parses the hierarchy of the document as well. So if the `CLAUDE.md` looks like this:

    # Project rules

    @rule1.md
    @rule2.md

    # Some other important info
    …

… then the headlines in these rules files should start at H2, not H1. Because if your `rule1.md` file begins with a H1, e.g. `# Rule 1`, then semantically, it's not a part of the "Project rules" section anymore.


## Save tokens by abbreviating tool output

Working with Xcode has Claude using `xcodebuild` a lot. `xcodebuild` is very verbose in its output. AFAICT from looking at its logs, Claude Code has to process ~10kB (1k-1.2k words) for **every** `xcodebuild` call, successful or not.

Writing a simple wrapper around very chatty tools can save a lot of tokens. As an example, take [xcodebuild-wrapper](bin/xcodebuild-wrapper): It emits the same exit code as the script call that it wraps, but returns only the last 30 lines on success (which is usually enough) or just the lines containing errors on failure (plus 5 lines above and below as context).

That's usually way less than 2kB, and yields the same results.
