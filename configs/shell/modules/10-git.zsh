# Git aliases and functions

alias gcm='git commit -m'
alias gs='git status'
alias ga='git add .'
alias gl='git log'
alias gc='git checkout'
alias gr='git remote -v'

# Custom git function (main/master detection)
function git() {
  if [[ "$1" == "checkout" && ("$2" == "main" || "$2" == "master") && $# -eq 2 ]]; then
    local default_branch=$(command git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [[ -z "$default_branch" ]]; then
      if command git show-ref --verify --quiet refs/heads/main; then default_branch="main"
      elif command git show-ref --verify --quiet refs/heads/master; then default_branch="master"
      else default_branch="main"; fi
    fi
    command git checkout "$default_branch"
  else
    command git "$@"
  fi
}

function resetHard() {
  git reset --hard
  git submodule update --init
}

function lastAuthor() {
  git log -1 --pretty=format:'%an' | xargs
}

function gcma() {
  if [[ "Mike Silvis" != "$(lastAuthor)" ]]; then
    echo "Please create an initial commit before running"
    return
  fi
  git add .
  git commit --amend --no-edit
}
