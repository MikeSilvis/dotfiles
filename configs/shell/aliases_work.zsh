# =============================================================================
# Work Aliases and Functions (Square)
# =============================================================================

alias bepi='bundle exec pod install'

# Utility aliases
alias downloadSnapshotImages="bundle exec ./Scripts/download-view-test-images.rb $@ --use-netrc"

# =============================================================================
# Bazel / iOS Build Functions
# =============================================================================

function buildDependencies() {
  bazel build $(bazel query "kind('ios_application|test_suite', rdeps(..., $@/...))")
}

function bazeltest() {
  bundle exec rlib query $@ | bundle exec rlib test
}

function bazelRun() {
  bundle exec rlib query $@ | bundle exec rlib build
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

# =============================================================================
# Workflow Functions
# =============================================================================

function monday() {
  killall Xcode

  cd ~/Development/topsoil && git pull && ./compost mobile

  cd ~/Development/ios-register && git clean -xdf && ./tools/bazel clean --expunge && dxdd

  git cleanup-branches

  cd ~/Development/mcp-square && git pull

  # Sync dotfiles at the end (includes Oh My Zsh update)
  echo "🔄 Syncing dotfiles..."
  sync
}

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
