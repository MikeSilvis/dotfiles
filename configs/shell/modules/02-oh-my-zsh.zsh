# Oh My Zsh configuration

export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"
export ZSH_CACHE_DIR="$ZSH/cache"
export ZSH_COMPDUMP="$ZSH/cache/.zcompdump"
export DISABLE_UPDATE_PROMPT=true
export DISABLE_AUTO_UPDATE=true
ZSH_THEME=""
plugins=(git sudo alias-finder jsontools)
source "$ZSH/oh-my-zsh.sh"
