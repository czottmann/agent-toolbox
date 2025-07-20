#!/usr/bin/env fish

gum format -- "# Maintain `bin/*` symlinks in `/usr/local/bin/`"
echo

# Check if gum is available
if not command -v gum > /dev/null
    echo "Error: gum is required but not installed."
    echo "Install it with: brew install gum"
    return 1
end

function symlink_bin_scripts
    # Check if ./bin directory exists
    if not test -d "./bin"
        echo "Error: ./bin directory not found in current directory"
        return 1
    end

    # Main menu
    set action (gum choose "Create symlinks" "Remove symlinks" "Exit")

    switch $action
        case "Create symlinks"
            create_symlinks

        case "Remove symlinks"
            remove_symlinks

        case "Quit"
            echo "Goodbye!"
            return 0
    end
end

function create_symlinks
    echo "Creating symlinks from ./bin/ to /usr/local/bin/"

    # Get all files in ./bin/
    set bin_files (find ./bin -maxdepth 1 -type f)

    if test (count $bin_files) -eq 0
        echo "No executable files found in ./bin/"
        return 0
    end

    for file in $bin_files
        set basename (basename $file)
        set target_link "/usr/local/bin/$basename"
        set source_path (realpath $file)

        # Check if symlink already exists
        if test -L $target_link
            set existing_target (readlink $target_link)
            if test "$existing_target" = "$source_path"
                echo "✓ $basename already correctly symlinked"
                continue
            else
                echo "⚠ $basename exists and points to: $existing_target"
                set overwrite (gum choose "Overwrite" "Skip")
                if test "$overwrite" = "Skip"
                    echo "Skipped $basename"
                    continue
                end
            end
        else if test -e $target_link
            echo "⚠ $basename exists as a regular file"
            set overwrite (gum choose "Overwrite" "Skip")
            if test "$overwrite" = "Skip"
                echo "Skipped $basename"
                continue
            end
        end

        # Create the symlink
        if ln -sf $source_path $target_link
            echo "✓ Created symlink: $basename -> $source_path"
        else
            echo "✗ Failed to create symlink for $basename"
        end
    end

    echo "Symlink creation complete!"
end

function remove_symlinks
    echo "Removing symlinks from /usr/local/bin/ that point to ./bin/"

    set removed_count 0
    set bin_realpath (realpath ./bin)

    # Find all symlinks in /usr/local/bin that point to files in our ./bin
    for link in /usr/local/bin/*
        if test -L $link
            set target (readlink $link)
            set target_dir (dirname $target)
            set target_realpath (realpath $target_dir 2>/dev/null)

            if test "$target_realpath" = "$bin_realpath"
                set basename (basename $link)
                if rm $link
                    echo "✓ Removed symlink: $basename"
                    set removed_count (math $removed_count + 1)
                else
                    echo "✗ Failed to remove symlink: $basename"
                end
            end
        end
    end

    if test $removed_count -eq 0
        echo "No symlinks found pointing to ./bin/"
    else
        echo "Removed $removed_count symlink(s)"
    end
end

# Run the main function
symlink_bin_scripts
