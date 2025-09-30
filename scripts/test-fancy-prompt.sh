#!/bin/bash

# Test script for the fancy prompt
echo "Testing the fancy prompt..."
echo ""

# Source the prompt
source /Users/msilvis/Developer/dotfiles/configs/shell/fast-git-prompt.zsh

# Test in different directories
echo "Testing in home directory:"
cd ~
echo "Current prompt should show: user@host | time | status"
echo "└─ ~/path/to/current/dir [git info if in repo]"
echo ""

echo "Testing in dotfiles directory (should show git info):"
cd /Users/msilvis/Developer/dotfiles
echo "Current prompt should show git branch and status indicators"
echo ""

echo "Prompt test complete!"
