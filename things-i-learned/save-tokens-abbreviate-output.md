## Save tokens by abbreviating tool output

Working with Xcode has Claude using `xcodebuild` a lot. `xcodebuild` is very verbose in its output. AFAICT from looking at its logs, Claude Code has to process ~10kB (1k-1.2k words) for **every** `xcodebuild` call, successful or not.

Writing a simple wrapper around very chatty tools can save a lot of tokens. As an example, take [xcodebuild-wrapper](bin/xcodebuild-wrapper): It emits the same exit code as the script call that it wraps, but returns only the last 30 lines on success (which is usually enough) or just the lines containing errors on failure (plus 5 lines above and below as context).

That's usually way less than 2kB, and yields the same results.
