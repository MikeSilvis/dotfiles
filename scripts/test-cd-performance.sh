#!/bin/bash
# Test cd performance with different prompt configurations

echo "🕐 Testing cd performance..."

# Test 1: Basic cd performance
echo "📊 Testing basic cd performance:"
time (cd /tmp && cd ~ && cd /tmp && cd ~) 2>&1 | grep real

echo ""
echo "📊 Testing cd in git repository:"
# Test 2: cd in a git repository (where git prompt would normally run)
if [ -d ~/Developer/dotfiles ]; then
    time (cd ~/Developer/dotfiles && cd /tmp && cd ~/Developer/dotfiles && cd /tmp) 2>&1 | grep real
else
    echo "No git repository found for testing"
fi

echo ""
echo "💡 Performance should be much faster now with the optimized git prompt!"
echo "💡 The heavy Square git prompt (588 lines) has been disabled"
echo "💡 You can switch back with: prompt-full"
