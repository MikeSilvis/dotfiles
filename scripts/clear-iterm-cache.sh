#!/bin/bash
# Clear iTerm2 cache files to improve performance

echo "🧹 Clearing iTerm2 cache files..."

# Function to safely remove cache files
clear_cache() {
    local cache_path="$1"
    local description="$2"
    
    if [ -e "$cache_path" ]; then
        echo "🗑️  Removing $description..."
        rm -rf "$cache_path"
        echo "✅ Cleared: $description"
    else
        echo "ℹ️  Not found: $description"
    fi
}

# Close iTerm2 first to avoid conflicts
echo "⚠️  Please close iTerm2 before running this script"
echo "Press Enter when iTerm2 is closed..."
read -r

# Clear main cache directory
clear_cache "$HOME/Library/Caches/com.googlecode.iterm2" "Main iTerm cache directory"

# Clear specific cache files
clear_cache "$HOME/Library/Caches/com.googlecode.iterm2/Cache.db" "Cache database"
clear_cache "$HOME/Library/Caches/com.googlecode.iterm2/Cache.db-shm" "Cache shared memory"
clear_cache "$HOME/Library/Caches/com.googlecode.iterm2/Cache.db-wal" "Cache write-ahead log"
clear_cache "$HOME/Library/Caches/com.googlecode.iterm2/fsCachedData" "File system cached data"

# Clear saved state (this will reset window positions, etc.)
clear_cache "$HOME/Library/Application Support/iTerm2/SavedState" "Saved window state"

# Clear chat database (if using iTerm's AI features)
clear_cache "$HOME/Library/Application Support/iTerm2/chatdb.sqlite" "Chat database"
clear_cache "$HOME/Library/Application Support/iTerm2/chatdb.sqlite-shm" "Chat database shared memory"

echo ""
echo "🎉 iTerm2 cache cleared successfully!"
echo "💡 Restart iTerm2 to see the improvements"
echo "⚠️  Note: Window positions and some settings may be reset"
