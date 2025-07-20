#!/usr/bin/env fish

gum format -- "# Maintain `commands/*` symlinks in `~/.claude/commands/`"
echo

# Check if gum is available
if not command -v gum > /dev/null
    echo "Error: gum is required but not installed."
    echo "Install it with: brew install gum"
    return 1
end

function symlink_command_files
    # Check if ./commands directory exists
    if not test -d "./commands"
        echo "Error: ./commands directory not found in current directory"
        return 1
    end

    # Create ~/.claude directory if it doesn't exist (but not the commands subdirectory)
    set claude_dir "$HOME/.claude"
    if not test -d $claude_dir
        echo "Creating directory: $claude_dir"
        mkdir -p $claude_dir
    end

    # Main menu
    set action (gum choose "Create symlink" "Remove symlink" "Exit")

    switch $action
        case "Create symlink"
            create_symlinks

        case "Remove symlink"
            remove_symlinks

        case "Exit"
            echo "Goodbye!"
            return 0
    end
end

function create_symlinks
    set target_link "$HOME/.claude/commands"
    set source_path (realpath ./commands)
    
    echo "Creating symlink from ./commands/ to $target_link"

    # Check if symlink already exists
    if test -L $target_link
        set existing_target (readlink $target_link)
        if test "$existing_target" = "$source_path"
            echo "✓ commands directory already correctly symlinked"
            return 0
        else
            echo "⚠ $target_link exists and points to: $existing_target"
            set overwrite (gum choose "Overwrite" "Skip")
            if test "$overwrite" = "Skip"
                echo "Skipped commands directory"
                return 0
            end
        end
    else if test -e $target_link
        echo "⚠ $target_link exists as a regular directory/file"
        set overwrite (gum choose "Overwrite" "Skip")
        if test "$overwrite" = "Skip"
            echo "Skipped commands directory"
            return 0
        end
        # Remove existing directory/file
        rm -rf $target_link
    end

    # Create the symlink
    if ln -sf $source_path $target_link
        echo "✓ Created symlink: $target_link -> $source_path"
    else
        echo "✗ Failed to create symlink for commands directory"
    end

    echo "Symlink creation complete!"
end

function remove_symlinks
    set target_link "$HOME/.claude/commands"
    set commands_realpath (realpath ./commands)
    
    echo "Removing symlink $target_link if it points to ./commands/"

    # Check if the target is a symlink pointing to our commands directory
    if test -L $target_link
        set existing_target (readlink $target_link)
        if test "$existing_target" = "$commands_realpath"
            if rm $target_link
                echo "✓ Removed symlink: $target_link"
            else
                echo "✗ Failed to remove symlink: $target_link"
            end
        else
            echo "⚠ $target_link points to a different location: $existing_target"
            echo "Not removing (it doesn't point to ./commands/)"
        end
    else if test -e $target_link
        echo "⚠ $target_link exists but is not a symlink"
        echo "Not removing (it's not a symlink to ./commands/)"
    else
        echo "No symlink found at $target_link"
    end
end

# Run the main function
symlink_command_files