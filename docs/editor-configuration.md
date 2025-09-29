# Editor Configuration Guide

This document describes the Cursor and VSCode configuration included in Mike's dotfiles and how to customize it.

## 📝 Included Editor Configurations

### Cursor
- **Settings**: `configs/editors/cursor/settings.json`
- **Keybindings**: `configs/editors/cursor/keybindings.json`
- **Extensions**: `configs/editors/cursor/extensions.txt`

### VSCode
- **Settings**: `configs/editors/vscode/settings.json`
- **Extensions**: `configs/editors/vscode/extensions.txt`

## 🚀 Installation

### Automatic Installation
Editor configurations are automatically installed when you run the main sync tool:

```bash
./bin/dotfiles-sync
```

### Manual Installation
Editor configurations are included in the main sync tool. To sync everything:

```bash
./bin/dotfiles-sync
```

### Dry Run
To see what would be synced without making changes:

```bash
./bin/dotfiles-sync --dry-run
```

## ⚙️ Configuration Details

### Cursor Configuration
- **Settings**: `~/Library/Application Support/Cursor/User/settings.json`
- **Keybindings**: `~/Library/Application Support/Cursor/User/keybindings.json`
- **Extensions**: Installed via `cursor --install-extension`

### VSCode Configuration
- **Settings**: `~/Library/Application Support/Code/User/settings.json`
- **Extensions**: Installed via `code --install-extension`

## 🎯 What Gets Synced

### Settings
- Editor preferences and configurations
- Theme and color scheme settings
- Font and display settings
- Language-specific settings
- Git integration settings
- Terminal settings

### Keybindings
- Custom keyboard shortcuts
- Vim keybindings (if enabled)
- Custom command shortcuts
- Multi-cursor operations

### Extensions
- All installed extensions are listed in `extensions.txt`
- Extensions are automatically installed during sync
- Extensions are installed in the same order as the original setup

## 🔧 Customization

### Adding New Extensions
1. Install the extension in your editor
2. Export the extensions list:
   ```bash
   # For Cursor
   cursor --list-extensions > configs/editors/cursor/extensions.txt
   
   # For VSCode
   code --list-extensions > configs/editors/vscode/extensions.txt
   ```
3. Commit the updated extensions list

### Modifying Settings
1. Make changes in your editor's settings UI
2. Copy the updated settings:
   ```bash
   # For Cursor
   cp ~/Library/Application\ Support/Cursor/User/settings.json configs/editors/cursor/
   
   # For VSCode
   cp ~/Library/Application\ Support/Code/User/settings.json configs/editors/vscode/
   ```
3. Commit the updated settings

### Custom Keybindings
1. Modify keybindings in your editor
2. Copy the updated keybindings:
   ```bash
   # For Cursor
   cp ~/Library/Application\ Support/Cursor/User/keybindings.json configs/editors/cursor/
   ```
3. Commit the updated keybindings

## 📦 Popular Extensions Included

### Development
- **GitLens**: Enhanced Git capabilities
- **ESLint**: JavaScript/TypeScript linting
- **Prettier**: Code formatting
- **Bracket Pair Colorizer**: Visual bracket matching

### Language Support
- **Python**: Python development
- **Java**: Java development
- **Swift**: Swift development
- **Go**: Go development
- **Rust**: Rust development

### Productivity
- **Vim**: Vim keybindings
- **Auto Rename Tag**: HTML tag management
- **Path Intellisense**: File path autocomplete
- **Todo Tree**: Task management

## 🔄 Migration from Other Editors

### From Sublime Text
1. Export Sublime settings and keybindings
2. Convert to VSCode/Cursor format
3. Install equivalent extensions

### From Atom
1. Export Atom configuration
2. Convert to VSCode/Cursor format
3. Install equivalent extensions

### From IntelliJ/WebStorm
1. Export IntelliJ settings
2. Convert to VSCode/Cursor format
3. Install equivalent extensions

## 🚨 Troubleshooting

### Extensions Not Installing
1. **Check editor installation**: Ensure Cursor/VSCode is properly installed
2. **Check command line tools**: Ensure `cursor` or `code` commands are available
3. **Check permissions**: Ensure you have write access to the extensions directory

### Settings Not Applied
1. **Restart editor**: Settings are loaded on startup
2. **Check file permissions**: Ensure settings files are readable
3. **Check JSON syntax**: Validate settings.json syntax

### Keybindings Not Working
1. **Check conflicts**: Ensure no conflicting keybindings
2. **Restart editor**: Keybindings are loaded on startup
3. **Check JSON syntax**: Validate keybindings.json syntax

### Performance Issues
1. **Disable unused extensions**: Remove extensions you don't use
2. **Check settings**: Optimize editor settings for performance
3. **Update extensions**: Ensure all extensions are up to date

## 📝 Best Practices

### Settings Management
- Keep settings minimal and focused
- Document custom settings with comments
- Use workspace-specific settings when appropriate
- Regularly review and clean up unused settings

### Extension Management
- Only install extensions you actually use
- Regularly update extensions
- Remove unused extensions
- Use extension recommendations for teams

### Keybinding Management
- Use consistent keybindings across editors
- Document custom keybindings
- Avoid conflicts with system shortcuts
- Test keybindings after changes

## 🔗 Useful Resources

- [VSCode Settings Reference](https://code.visualstudio.com/docs/getstarted/settings)
- [VSCode Keybindings Reference](https://code.visualstudio.com/docs/getstarted/keybindings)
- [VSCode Extensions Marketplace](https://marketplace.visualstudio.com/)
- [Cursor Documentation](https://cursor.sh/docs)

## 📞 Support

If you encounter issues with editor configuration:

1. Check this guide's troubleshooting section
2. Verify editor installation and command line tools
3. Check file permissions and JSON syntax
4. Restart editors after making changes
5. Open an issue in the dotfiles repository if needed
