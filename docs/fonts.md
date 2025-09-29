# Font Configuration Guide

This document describes the fonts included in Mike's dotfiles and their recommended usage.

## Included Fonts

### Source Code Pro
- **Files**: `SourceCodePro-*.otf`
- **Description**: Adobe's open source monospace font family
- **Best for**: General coding, terminal use
- **Features**: Excellent readability, multiple weights
- **Usage**: Default font for most development tools

### Fira Code
- **Files**: `FiraCode-VF.ttf`
- **Description**: Mozilla's monospace font with programming ligatures
- **Best for**: Modern code editors, especially with ligature support
- **Features**: Programming ligatures (->, =>, !=, etc.)
- **Usage**: Recommended for VS Code, Sublime Text, and other modern editors

### Meslo LG for Powerline
- **Files**: `Meslo LG L Regular for Powerline.ttf`
- **Description**: Apple's Menlo font modified for Powerline
- **Best for**: Terminal use with Oh My Zsh themes
- **Features**: Powerline symbols support
- **Usage**: Terminal fonts, especially with Agnoster theme

## Recommended Additional Fonts

### JetBrains Mono
- **Download**: [GitHub Releases](https://github.com/JetBrains/JetBrainsMono/releases)
- **Description**: JetBrains' modern monospace font
- **Best for**: JetBrains IDEs, general development
- **Features**: Excellent ligature support, designed for coding

### Cascadia Code
- **Download**: [GitHub Releases](https://github.com/microsoft/cascadia-code/releases)
- **Description**: Microsoft's monospace font
- **Best for**: Windows Terminal, VS Code, general development
- **Features**: Programming ligatures, multiple weights

## Font Installation

### Automatic Installation
Fonts are automatically installed when you run the main sync tool:

```bash
./bin/dotfiles-sync
```

### Manual Installation
Fonts and themes are included in the main sync tool. To sync everything:

```bash
./bin/dotfiles-sync
```

### Dry Run
To see what would be synced without making changes:

```bash
./bin/dotfiles-sync --dry-run
```

## Font Usage Recommendations

### Terminal
- **Primary**: Meslo LG for Powerline (for Oh My Zsh themes)
- **Alternative**: Source Code Pro
- **Size**: 14-16pt depending on display

### Code Editors
- **VS Code**: Fira Code or JetBrains Mono (with ligatures enabled)
- **Vim/Neovim**: Source Code Pro or Fira Code
- **Xcode**: SF Mono (system default) or Source Code Pro

### IDEs
- **IntelliJ/WebStorm**: JetBrains Mono
- **Xcode**: SF Mono or Source Code Pro
- **Android Studio**: JetBrains Mono or Source Code Pro

## Enabling Ligatures

### VS Code
1. Open Settings (Cmd+,)
2. Search for "font ligatures"
3. Enable "Editor: Font Ligatures"
4. Set font family to "Fira Code" or "JetBrains Mono"

### Vim/Neovim
Add to your vimrc:
```vim
set guifont=Fira\ Code:h14
```

### Terminal
Most modern terminals support ligatures automatically when using compatible fonts.

## Troubleshooting

### Fonts Not Appearing
1. Restart the application after installation
2. Check that fonts are in `~/Library/Fonts/`
3. Verify font files are not corrupted

### Ligatures Not Working
1. Ensure your editor supports ligatures
2. Check that ligatures are enabled in editor settings
3. Verify you're using a font that supports ligatures

### Font Rendering Issues
1. Clear font caches: `sudo atsutil databases -remove`
2. Restart the application
3. Check font file integrity

## Custom Font Installation

To add your own fonts:

1. Place font files in `configs/fonts/`
2. Run the installer: `ruby scripts/install.rb`
3. Restart your applications

Supported formats: `.ttf`, `.otf`, `.ttc`
