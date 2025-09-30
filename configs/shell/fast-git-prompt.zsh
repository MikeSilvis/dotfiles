# =============================================================================
# Fast Git Prompt - Optimized for Performance
# =============================================================================
# This is a lightweight alternative to the heavy Square git prompt
# that was causing slow cd performance (588 lines of git operations)

# Enable prompt substitution
setopt prompt_subst

# Fast git prompt function
function fast_git_prompt() {
    # Only run git commands if we're in a git repository
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Get current branch (fast operation)
        local branch=$(git branch --show-current 2>/dev/null)
        
        if [[ -n "$branch" ]]; then
            # Check if there are any changes (single git command)
            local git_status=$(git status --porcelain 2>/dev/null | wc -l)
            
            if [[ $git_status -gt 0 ]]; then
                echo " %F{yellow}($branch*)%F{reset}"
            else
                echo " %F{green}($branch)%F{reset}"
            fi
        fi
    fi
}

# Set the prompt with fast git info
PROMPT='%F{251}%~%F{reset}$(fast_git_prompt) '

# Alternative: Even faster version that only shows branch name
# Uncomment this and comment out the above for maximum speed
# PROMPT='%F{251}%~%F{reset} %F{cyan}$(git branch --show-current 2>/dev/null)%F{reset} '
