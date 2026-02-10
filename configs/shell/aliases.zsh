# =============================================================================
# Aliases, Functions, and Development Tools
# =============================================================================

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# =============================================================================
# Android Development Configuration
# =============================================================================

# Android SDK configuration
# The SDK is typically installed at ~/Library/Android/sdk (Android Studio)
# or /usr/local/share/android-sdk (Homebrew)
if [ -d "$HOME/Library/Android/sdk" ]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
elif [ -d "/usr/local/share/android-sdk" ]; then
    export ANDROID_HOME="/usr/local/share/android-sdk"
    export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"
fi

# Add Android SDK tools to PATH if ANDROID_HOME is set
if [ -n "$ANDROID_HOME" ]; then
    # Core tools (always available)
    [ -d "$ANDROID_HOME/emulator" ] && export PATH="$ANDROID_HOME/emulator:$PATH"
    [ -d "$ANDROID_HOME/platform-tools" ] && export PATH="$ANDROID_HOME/platform-tools:$PATH"
    
    # Command-line tools (sdkmanager, avdmanager)
    # Install via: Android Studio > Settings > SDK Manager > SDK Tools > Android SDK Command-line Tools
    [ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ] && export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
    
    # Legacy tools directory (deprecated but may exist)
    [ -d "$ANDROID_HOME/tools" ] && export PATH="$ANDROID_HOME/tools:$PATH"
    [ -d "$ANDROID_HOME/tools/bin" ] && export PATH="$ANDROID_HOME/tools/bin:$PATH"
    
    # Build tools
    if [ -d "$ANDROID_HOME/build-tools" ]; then
        # Add the latest build-tools version to PATH
        LATEST_BUILD_TOOLS=$(ls -1 "$ANDROID_HOME/build-tools" | sort -V | tail -1)
        [ -n "$LATEST_BUILD_TOOLS" ] && export PATH="$ANDROID_HOME/build-tools/$LATEST_BUILD_TOOLS:$PATH"
    fi
fi

# =============================================================================
# Git Aliases and Functions
# =============================================================================

alias gcm='git commit -m'
alias gs='git status'
alias ga='git add .'
alias gl='git log'
alias gc='git checkout'
alias gr='git remote -v'

# Git utility functions
function resetHard() {
  git reset --hard
  git submodule update --init
}

function lastAuthor() {
  git log -1 --pretty=format:'%an'  | xargs
}

function gcma() {
  if [[ "Mike Silvis" != "$(lastAuthor)" ]]; then
    echo "Please create an initial commit before running"
    return
  fi

  git add .
  git commit --amend --no-edit
}

# =============================================================================
# Development Aliases and Functions
# =============================================================================

alias bepi='bundle exec pod install'

# Bazel functions
function buildDependencies() {
  bazel build $(bazel query "kind('ios_application|test_suite', rdeps(..., $@/...))")
}

function bazeltest() {
  bundle exec rlib query $@ | bundle exec rlib test
}

function bazelRun() {
  bundle exec rlib query $@ | bundle exec rlib build
}

# Development workflow functions
function monday() {
  killall Xcode

  # Clear iTerm cache for better performance
  echo "🧹 Clearing iTerm cache..."
  rm -rf ~/Library/Caches/com.googlecode.iterm2 2>/dev/null || true
  rm -rf ~/Library/Application\ Support/iTerm2/SavedState 2>/dev/null || true
  rm -f ~/Library/Application\ Support/iTerm2/chatdb.sqlite* 2>/dev/null || true
  echo "✅ iTerm cache cleared"

  cd ~/Development/topsoil && git pull && ./compost mobile

  cd ~/Development/ios-register && git clean -xdf && ./tools/bazel clean --expunge && dxdd

  git cleanup-branches

  cd ~/Development/mcp-square && git pull

  # Sync dotfiles at the end (includes Oh My Zsh update)
  echo "🔄 Syncing dotfiles..."
  sync
}

function superpos() {
  sq gen \
    SPOS \
        --user-build-settings=--//Verticals/SPOS:superpos_invoices=true \
        --user-build-settings=--//Verticals/SPOS:superpos_retail=true \
        --user-build-settings=--//Verticals/SPOS:superpos_appointments=true \
        --user-build-settings=--//Verticals/SPOS:superpos_restaurant=true \
        --auto-open \
        --name SuperPOS
}

# Utility aliases
alias downloadSnapshotImages="bundle exec ./Scripts/download-view-test-images.rb $@ --use-netrc"

# =============================================================================
# Dotfiles Management
# =============================================================================

# sync() - Run dotfiles sync from anywhere
# Usage: sync [--dry-run] [--verbose] [--force]
function sync() {
    if [[ -z "$DOTFILES_DIR" ]]; then
        echo "❌ DOTFILES_DIR not set — is your zshrc configured?"
        return 1
    fi

    cd "$DOTFILES_DIR" || return 1
    echo "🚀 Running dotfiles sync..."
    ./bin/dotfiles-sync "$@"
    echo "🔄 Updating Oh My Zsh..."
    omz update
    cd - > /dev/null
}

# Convenient aliases for common sync operations
alias sync-dry='sync --dry-run'
alias sync-verbose='sync --verbose'
alias sync-force='sync --force'

# =============================================================================
# Cache Management Functions
# =============================================================================

# clear-iterm-cache() - Clear iTerm2 cache files for better performance
function clear-iterm-cache() {
    echo "🧹 Clearing iTerm2 cache files..."
    
    # Close iTerm2 first
    echo "⚠️  Please close iTerm2 before clearing cache"
    echo "Press Enter when iTerm2 is closed..."
    read -r
    
    # Clear cache files
    local cache_dir="$HOME/Library/Caches/com.googlecode.iterm2"
    if [ -d "$cache_dir" ]; then
        echo "🗑️  Removing iTerm cache directory..."
        rm -rf "$cache_dir"
        echo "✅ Cleared iTerm cache"
    else
        echo "ℹ️  No iTerm cache found"
    fi
    
    # Clear saved state
    local saved_state="$HOME/Library/Application Support/iTerm2/SavedState"
    if [ -d "$saved_state" ]; then
        echo "🗑️  Removing saved state..."
        rm -rf "$saved_state"
        echo "✅ Cleared saved state"
    fi
    
    echo "🎉 iTerm cache cleared! Restart iTerm2 to see improvements."
}

# Aliases for cache management
alias clear-cache='clear-iterm-cache'
alias iterm-cache='clear-iterm-cache'

# Editor aliases
alias c='cursor .'                    # Open Cursor in current directory
alias cursor-here='cursor .'          # Alternative alias for opening Cursor
alias cursor-new='cursor'             # Open new Cursor window

# Aliases for extension management
alias install-exts='install-extensions'

# install-extensions() - Manually install Cursor extensions that failed during sync
function install-extensions() {
    if ! command -v cursor >/dev/null 2>&1; then
        echo "❌ Cursor not found"
        return 1
    fi

    local extensions_file="$DOTFILES_DIR/configs/editors/cursor/extensions.txt"
    if [[ ! -f "$extensions_file" ]]; then
        echo "❌ Extensions file not found: $extensions_file"
        return 1
    fi

    echo "📦 Installing Cursor extensions..."
    while IFS= read -r extension; do
        if [[ -n "$extension" ]]; then
            echo "  Installing: $extension"
            cursor --install-extension "$extension" || echo "    ⚠️  Failed to install $extension"
        fi
    done < "$extensions_file"
    echo "✅ Extension installation complete!"
}

# check-compatibility() - Check dotfiles mode and environment
function check-compatibility() {
    echo "🔍 Checking dotfiles environment..."

    # Detect mode
    if [[ -d ~/Development/config_files ]]; then
        echo "🖥️  Mode: WORK (config_files detected)"
    else
        echo "💻 Mode: PERSONAL"
    fi

    # Check zshrc stub
    if [[ -f ~/.zshrc ]]; then
        local zshrc_source=$(grep '^source ' ~/.zshrc | tail -1)
        echo "📄 ~/.zshrc sources: ${zshrc_source#source }"
    fi

    # Check Ruby version manager
    if command -v rvm >/dev/null 2>&1; then
        echo "💎 Ruby manager: RVM ($(rvm current 2>/dev/null || echo 'unknown'))"
    elif command -v mise >/dev/null 2>&1; then
        echo "💎 Ruby manager: mise"
    else
        echo "⚠️  No Ruby version manager found"
    fi

    # Check if Square configs are loaded (work mode)
    if [[ -n "$SQUARE_HOME" ]]; then
        echo "✅ SQUARE_HOME is set: $SQUARE_HOME"
    fi

    # Check Oh My Posh
    if command -v oh-my-posh >/dev/null 2>&1; then
        echo "✅ Oh My Posh available"
    else
        echo "⚠️  Oh My Posh not found"
    fi
}
alias sync-help='sync --help'

# dotfiles-status() - Check the status of your dotfiles repository
function dotfiles-status() {
    if [[ -z "$DOTFILES_DIR" ]]; then
        echo "❌ DOTFILES_DIR not set"
        return 1
    fi

    cd "$DOTFILES_DIR" || return 1
    echo "📁 Dotfiles Repository Status:"
    echo "📍 Location: $DOTFILES_DIR"
    echo "🌿 Branch: $(git branch --show-current 2>/dev/null)"
    echo "📊 Status: $(git status --porcelain 2>/dev/null | wc -l | xargs) uncommitted changes"
    echo "🔄 Last sync: $(git log -1 --format='%ar' 2>/dev/null)"
    cd - > /dev/null
}

# =============================================================================
# Work-specific Functions (Square)
# =============================================================================

function override-owner-owl() {
  SHA="$1"
  OVERRIDE_REASON="$2"
  CHECK_NAME="Owner Owl"

  if [[ -z $SHA ]]; then
    echo "Must provide a SHA and override reason"
    return 1
  fi

  if [[ -z $OVERRIDE_REASON ]]; then
    echo "Must provide a SHA and override reason"
    return 1
  fi

  bundle exec sq-github-notify-commit-status \
    --fail \
    --silent \
    --repo squareup/ios-register \
    --sha "$SHA" \
    --state success \
    --name "$CHECK_NAME" \
    --description "$OVERRIDE_REASON"
}