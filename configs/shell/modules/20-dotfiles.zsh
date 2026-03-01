# Dotfiles management functions

function sync() {
    if [[ -z "$DOTFILES_DIR" ]]; then
        echo "DOTFILES_DIR not set -- is your zshrc configured?"
        return 1
    fi
    cd "$DOTFILES_DIR" || return 1
    echo "Running dotfiles sync..."
    ./bin/dotfiles-sync "$@"
    echo "Updating Oh My Zsh..."
    omz update
    cd - > /dev/null
}

function cleanup-sims() {
    if [[ -z "$DOTFILES_DIR" ]]; then
        echo "DOTFILES_DIR not set -- is your zshrc configured?"
        return 1
    fi
    "$DOTFILES_DIR/bin/cleanup-sims" "$@"
}

function cleanup-space() {
    if [[ -z "$DOTFILES_DIR" ]]; then
        echo "DOTFILES_DIR not set -- is your zshrc configured?"
        return 1
    fi
    "$DOTFILES_DIR/bin/cleanup-space" "$@"
}

alias cleanup-sims-dry='cleanup-sims --dry-run'
alias cleanup-space-dry='cleanup-space --dry-run'

alias sync-dry='sync --dry-run'
alias sync-verbose='sync --verbose'
alias sync-force='sync --force'
alias sync-help='sync --help'

function dotfiles-status() {
    if [[ -z "$DOTFILES_DIR" ]]; then
        echo "DOTFILES_DIR not set"
        return 1
    fi
    cd "$DOTFILES_DIR" || return 1
    echo "Dotfiles Repository Status:"
    echo "  Location: $DOTFILES_DIR"
    echo "  Branch: $(git branch --show-current 2>/dev/null)"
    echo "  Status: $(git status --porcelain 2>/dev/null | wc -l | xargs) uncommitted changes"
    echo "  Last sync: $(git log -1 --format='%ar' 2>/dev/null)"
    cd - > /dev/null
}

function check-compatibility() {
    echo "Checking dotfiles environment..."
    if [[ -d ~/Development/config_files ]]; then
        echo "  Mode: WORK (config_files detected)"
    else
        echo "  Mode: PERSONAL"
    fi
    if [[ -f ~/.zshrc ]]; then
        local zshrc_source=$(grep '^source ' ~/.zshrc | tail -1)
        echo "  ~/.zshrc sources: ${zshrc_source#source }"
    fi
    if command -v rvm >/dev/null 2>&1; then
        echo "  Ruby manager: RVM ($(rvm current 2>/dev/null || echo 'unknown'))"
    elif command -v mise >/dev/null 2>&1; then
        echo "  Ruby manager: mise"
    else
        echo "  No Ruby version manager found"
    fi
    if [[ -n "$SQUARE_HOME" ]]; then
        echo "  SQUARE_HOME is set: $SQUARE_HOME"
    fi
    if command -v oh-my-posh >/dev/null 2>&1; then
        echo "  Oh My Posh available"
    else
        echo "  Oh My Posh not found"
    fi
}
