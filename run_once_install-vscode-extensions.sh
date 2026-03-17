#!/bin/bash
if ! command -v code &> /dev/null; then
    echo "VS Code not found, skipping extension install"
    exit 0
fi

extensions_file="$HOME/.config/Code/User/extensions.txt"
if [ ! -f "$extensions_file" ]; then
    echo "Extensions list not found at $extensions_file"
    exit 0
fi

installed=$(code --list-extensions 2>/dev/null)

while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    if echo "$installed" | grep -qi "^${ext}$"; then
        echo "Already installed: $ext"
    else
        echo "Installing: $ext"
        code --install-extension "$ext" --force 2>/dev/null
    fi
done < "$extensions_file"
