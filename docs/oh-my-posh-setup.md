# Oh My Posh Setup Guide

This guide covers the Oh My Posh configuration in your dotfiles, including installation, customization, and troubleshooting.

## 🎨 Current Configuration

Your terminal prompt uses the **Gruvbox theme** from Oh My Posh, providing:

- **Warm, muted colors** that are easy on the eyes
- **Professional powerline segments** with smooth transitions
- **Git integration** with branch info and status indicators
- **Directory path** with clean display
- **User@host information**
- **Exit status indicators**
- **Proper Nerd Font icons** for all elements

## 🚀 Installation

Oh My Posh is automatically installed via Homebrew when you run the dotfiles sync:

```bash
# Install Oh My Posh
brew install oh-my-posh

# Install Nerd Font for proper icon display
brew install font-meslo-lg-nerd-font
```

## ⚙️ Configuration

The Oh My Posh configuration is set in your `~/.zshrc` file:

```bash
# Oh My Posh - Gruvbox Theme
eval "$(oh-my-posh init zsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/gruvbox.omp.json)"
```

This configuration:
- Loads the Gruvbox theme directly from the official Oh My Posh repository
- Initializes Oh My Posh for zsh
- Sets up the prompt with all Gruvbox styling and functionality

## 🎨 Available Themes

Oh My Posh offers many beautiful themes. Here are some popular alternatives:

### Popular Themes
- **Gruvbox** (current) - Warm, muted colors
- **Powerlevel10k** - Fast and highly customizable
- **Agnoster** - Classic powerline style
- **Paradox** - Clean and minimal
- **Robbyrussell** - Simple and elegant
- **M365Princess** - Microsoft-inspired
- **Atomic** - Modern and colorful

### Theme URLs
```bash
# Gruvbox (current)
https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/gruvbox.omp.json

# Powerlevel10k
https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/powerlevel10k_lean.omp.json

# Agnoster
https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/agnoster.omp.json

# Paradox
https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/paradox.omp.json
```

## 🔧 Customization

### Changing Themes

To change your theme, edit the configuration in `~/.zshrc`:

```bash
# Replace the current theme URL with your desired theme
eval "$(oh-my-posh init zsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/theme-name.omp.json)"
```

Then reload your shell:
```bash
source ~/.zshrc
```

### Local Theme Configuration

For more advanced customization, you can download a theme locally and modify it:

```bash
# Download a theme locally
curl -o ~/.oh-my-posh-theme.omp.json https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/gruvbox.omp.json

# Use the local theme
eval "$(oh-my-posh init zsh --config ~/.oh-my-posh-theme.omp.json)"
```

### Customizing Segments

You can modify the theme JSON to:
- Add or remove segments
- Change colors
- Modify icons
- Adjust spacing and alignment

## 🔤 Font Configuration

Oh My Posh requires a Nerd Font for proper icon display. The setup includes Meslo LG Nerd Font.

### Setting the Font in Terminal

1. **iTerm2**:
   - Go to Preferences → Profiles → Text
   - Change font to "MesloLGLDZNerdFont-Regular"

2. **Terminal.app**:
   - Go to Preferences → Profiles → Text
   - Change font to "MesloLGLDZNerdFont-Regular"

3. **VS Code Terminal**:
   - Go to Settings → Terminal → Integrated → Font Family
   - Set to "MesloLGLDZNerdFont-Regular"

### Alternative Nerd Fonts

If you prefer different fonts:
```bash
# Install other popular Nerd Fonts
brew install font-fira-code-nerd-font
brew install font-hack-nerd-font
brew install font-jetbrains-mono-nerd-font
brew install font-source-code-pro-nerd-font
```

## 🐛 Troubleshooting

### Prompt Not Showing

If the prompt doesn't appear:

```bash
# Check if Oh My Posh is installed
oh-my-posh --version

# Check if the theme is loading
oh-my-posh init zsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/gruvbox.omp.json

# Reload shell configuration
source ~/.zshrc
```

### Icons Not Displaying

If icons appear as boxes or question marks:

1. **Check your terminal font** - ensure it's set to a Nerd Font
2. **Restart your terminal** after changing fonts
3. **Verify font installation**:
   ```bash
   # List installed fonts
   fc-list | grep -i nerd
   ```

### Performance Issues

If the prompt is slow:

1. **Check git repository size** - large repos can slow down git segments
2. **Disable heavy segments** in the theme configuration
3. **Use a lighter theme** like Paradox or Robbyrussell

### Theme Not Loading

If the theme doesn't load:

1. **Check internet connection** - themes are loaded from GitHub
2. **Try a local theme** - download the theme file locally
3. **Check Oh My Zsh conflicts** - ensure ZSH_THEME is empty

## 🔄 Updates

To update Oh My Posh:

```bash
# Update via Homebrew
brew upgrade oh-my-posh

# Reload configuration
source ~/.zshrc
```

## 📚 Additional Resources

- [Oh My Posh Documentation](https://ohmyposh.dev/)
- [Theme Gallery](https://ohmyposh.dev/docs/themes)
- [Configuration Guide](https://ohmyposh.dev/docs/configuration)
- [Nerd Fonts](https://www.nerdfonts.com/)

## 🎯 Best Practices

1. **Keep themes updated** - Oh My Posh themes are actively maintained
2. **Use official themes** - avoid custom modifications unless necessary
3. **Test performance** - ensure the prompt doesn't slow down your terminal
4. **Backup customizations** - save any local theme modifications
5. **Document changes** - note any custom configurations for future reference
