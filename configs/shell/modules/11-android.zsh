# Android Development Configuration

if [ -d "$HOME/Library/Android/sdk" ]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
elif [ -d "/usr/local/share/android-sdk" ]; then
    export ANDROID_HOME="/usr/local/share/android-sdk"
    export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"
fi

if [ -n "$ANDROID_HOME" ]; then
    [ -d "$ANDROID_HOME/emulator" ] && export PATH="$ANDROID_HOME/emulator:$PATH"
    [ -d "$ANDROID_HOME/platform-tools" ] && export PATH="$ANDROID_HOME/platform-tools:$PATH"
    [ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ] && export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
    [ -d "$ANDROID_HOME/tools" ] && export PATH="$ANDROID_HOME/tools:$PATH"
    [ -d "$ANDROID_HOME/tools/bin" ] && export PATH="$ANDROID_HOME/tools/bin:$PATH"
    if [ -d "$ANDROID_HOME/build-tools" ]; then
        LATEST_BUILD_TOOLS=$(ls -1 "$ANDROID_HOME/build-tools" | sort -V | tail -1)
        [ -n "$LATEST_BUILD_TOOLS" ] && export PATH="$ANDROID_HOME/build-tools/$LATEST_BUILD_TOOLS:$PATH"
    fi
fi
