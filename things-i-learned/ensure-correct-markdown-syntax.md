## Make sure your rules are syntactically correct

Modularizing [the rules](rules/) is a good idea, but it's also a good idea to _ensure_ that Claude can read them correctly.

Case in point: One of the rules contained a code block that contained code blocks, like this:

<pre><code>```markdown
# Something something

```bash
```
```</code></pre>

As a human, I could comprehend it, but a Markdown parser can't. Claude read _everything_ below that point as being part of a code block, basically ignoring it. I only noticed that something was off because one of the rules that were `@`-imported below it weren't followed.

It took me a while to find the Markdown issue but it became clear once I rendered Claude's context out into a separate file (using [render-claude-context](https://github.com/czottmann/render-claude-context)), and skimmed it using [glow](https://github.com/charmbracelet/glow) (another Markdown viewer would've worked, too):

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
