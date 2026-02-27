# Editor and tool aliases

alias claude='claude --dangerously-skip-permissions'

alias c='cursor .'
alias cursor-here='cursor .'
alias cursor-new='cursor'
alias install-exts='install-extensions'

function install-extensions() {
    if ! command -v cursor >/dev/null 2>&1; then
        echo "Cursor not found"
        return 1
    fi
    local extensions_file="$DOTFILES_DIR/configs/editors/cursor/extensions.txt"
    if [[ ! -f "$extensions_file" ]]; then
        echo "Extensions file not found: $extensions_file"
        return 1
    fi
    echo "Installing Cursor extensions..."
    while IFS= read -r extension; do
        if [[ -n "$extension" ]]; then
            echo "  Installing: $extension"
            cursor --install-extension "$extension" || echo "    Failed to install $extension"
        fi
    done < "$extensions_file"
    echo "Extension installation complete!"
}
