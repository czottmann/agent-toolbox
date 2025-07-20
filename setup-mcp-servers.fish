#!/usr/bin/env fish

gum format -- "# Install MCP server(s) for `claude` in `$(pwd)`"
echo

# Check if gum is available
if not command -v gum > /dev/null
    echo "Error: gum is required but not installed."
    echo "Install it with: brew install gum"
    return 1
end

set options "
Linear MCP:linear
Sentry MCP:sentry
Quit:
"

set selection (echo $options | gum choose --label-delimiter=":" --header="")
test -z $selection && exit

gum confirm "Install $selection?" --default="No"
or exit 0

switch $selection
    case linear
        gum spin --spinner dot --title "Installing $selection…" -- \
            claude mcp add --transport sse linear https://mcp.linear.app/sse

    case sentry
        gum spin --spinner dot --title "Installing $selection…" -- \
            claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
end
and echo "✅ Installed."
echo

gum spin --spinner dot --title "Getting details…" --show-output -- \
    claude mcp get $selection
