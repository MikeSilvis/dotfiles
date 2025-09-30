#!/bin/bash
# Measure shell startup time

echo "🕐 Measuring shell startup times..."

echo "📊 Current optimized configuration:"
time zsh -c "source ~/.zshrc; echo 'Optimized shell loaded'" 2>&1 | grep real

echo ""
echo "🚀 Testing lazy loading triggers:"
echo "Testing node command (should trigger NVM load):"
time zsh -c "source ~/.zshrc; node --version" 2>&1 | grep real

echo "Testing git command (should trigger Oh My Zsh plugins):"
time zsh -c "source ~/.zshrc; git --version" 2>&1 | grep real

echo ""
echo "💡 To load all tools at once, run: load-all"
echo "💡 Individual load functions: load_nvm, load_rvm, load_mise, load_antigen_plugins"


