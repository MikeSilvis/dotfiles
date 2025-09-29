# iTerm2 Configuration Guide

This document describes the iTerm2 configuration included in Mike's dotfiles and how to customize it.

## 🎨 Included Color Schemes

### Smyck
- **File**: `Smyck.itermcolors`
- **Description**: Dark theme with good contrast and readability
- **Best for**: General development work, long coding sessions
- **Features**: Easy on the eyes, good syntax highlighting support

### Tokyo Night
- **File**: `tokyo-night.itermcolors` (if available)
- **Description**: Modern dark theme inspired by Tokyo's night sky
- **Best for**: Modern development environments
- **Features**: Beautiful color palette, excellent contrast

## 📋 Included Profiles

### Development Profile
- **File**: `Development.json`
- **Description**: Optimized profile for development work
- **Features**:
  - Starts in `~/Development` directory
  - Uses Source Code Pro font at 14pt
  - Green accent colors for development context
  - Text triggers for ERROR, WARNING, SUCCESS messages
  - 120 columns, 30 rows default size
  - 10,000 line scrollback buffer

## 🚀 Installation

### Automatic Installation
iTerm2 configuration is automatically installed when you run the main sync tool:

```bash
./bin/dotfiles-sync
```

### Manual Installation
iTerm2 configuration is included in the main sync tool. To sync everything:

```bash
./bin/dotfiles-sync
```

### Dry Run
To see what would be synced without making changes:

```bash
./bin/dotfiles-sync --dry-run
```

## ⚙️ Configuration Details

### Color Schemes
Color schemes are installed to:
```
~/Library/Application Support/iTerm2/ColorPresets/
```

### Preferences
Preferences are installed to:
```
~/Library/Preferences/com.googlecode.iterm2.plist
```

### Dynamic Profiles
Dynamic profiles are installed to:
```
~/Library/Application Support/iTerm2/DynamicProfiles/
```

## 🎯 Usage Recommendations

### Font Settings
- **Primary Font**: Source Code Pro Regular, 14pt
- **Alternative**: Meslo LG L Regular for Powerline (for Oh My Zsh themes)
- **Ligatures**: Enable if using Fira Code or JetBrains Mono

### Color Scheme Selection
1. Open iTerm2 Preferences (Cmd+,)
2. Go to Profiles > Colors
3. Select "Color Presets" dropdown
4. Choose "Smyck" or your preferred scheme

### Profile Usage
1. Open iTerm2 Preferences (Cmd+,)
2. Go to Profiles
3. Select "Development" profile
4. Set as default or use for specific projects

## 🔧 Customization

### Adding New Color Schemes
1. Download `.itermcolors` files from [iTerm2 Color Schemes](https://iterm2colorschemes.com/)
2. Place them in `configs/iterm2/`
3. Run the installer: `ruby scripts/install.rb`

### Creating Custom Profiles
1. Create a JSON file in `configs/iterm2/profiles/`
2. Follow the format of `Development.json`
3. Run the installer to install the profile

### Modifying Preferences
1. Configure iTerm2 as desired
2. Export preferences: `defaults export com.googlecode.iterm2 configs/iterm2/iterm2_preferences.plist`
3. Commit the changes to your dotfiles

## 🎨 Popular Color Schemes to Add

### Dracula
- **Download**: [Dracula.itermcolors](https://draculatheme.com/iterm)
- **Description**: Dark theme with purple accents
- **Best for**: Modern development, great contrast

### Solarized Dark
- **Download**: [Solarized Dark.itermcolors](https://ethanschoonover.com/solarized/)
- **Description**: Scientifically designed color palette
- **Best for**: Long coding sessions, reduced eye strain

### One Dark
- **Download**: [One Dark.itermcolors](https://github.com/joshdick/onedark.vim)
- **Description**: Atom editor's default dark theme
- **Best for**: VS Code users, familiar color scheme

### Gruvbox
- **Download**: [Gruvbox.itermcolors](https://github.com/morhetz/gruvbox)
- **Description**: Retro groove color scheme
- **Best for**: Retro aesthetic, warm colors

## 🔄 Migration from Other Terminals

### From Terminal.app
1. Export your Terminal preferences
2. Convert color schemes to iTerm2 format
3. Import profiles and preferences

### From Hyper
1. Copy color schemes from Hyper config
2. Convert to iTerm2 format
3. Set up similar profiles

### From Alacritty
1. Convert Alacritty color schemes
2. Set up similar font and size settings
3. Configure profiles for different contexts

## 🚨 Troubleshooting

### Color Schemes Not Appearing
1. **Check installation**: Verify files are in `~/Library/Application Support/iTerm2/ColorPresets/`
2. **Restart iTerm2**: Close and reopen iTerm2
3. **Check permissions**: Ensure files are readable

### Profiles Not Loading
1. **Check JSON format**: Validate JSON syntax
2. **Check file location**: Ensure profiles are in `DynamicProfiles/` directory
3. **Restart iTerm2**: Profiles are loaded on startup

### Preferences Not Applied
1. **Check file permissions**: Ensure plist file is readable
2. **Restart iTerm2**: Preferences are loaded on startup
3. **Check backup**: Restore from backup if needed

### Font Rendering Issues
1. **Install fonts**: Ensure required fonts are installed
2. **Check font names**: Use exact font names in profiles
3. **Clear font cache**: `sudo atsutil databases -remove`

## 📝 Best Practices

### Profile Organization
- Create separate profiles for different contexts (development, production, etc.)
- Use descriptive names and colors
- Set appropriate default directories

### Color Scheme Management
- Keep color schemes in version control
- Document which schemes work best for different use cases
- Test schemes in different lighting conditions

### Performance Optimization
- Limit scrollback buffer size for better performance
- Use appropriate font sizes for your display
- Disable unnecessary features if performance is an issue

## 🔗 Useful Resources

- [iTerm2 Official Documentation](https://iterm2.com/documentation.html)
- [iTerm2 Color Schemes](https://iterm2colorschemes.com/)
- [iTerm2 Profiles Documentation](https://iterm2.com/profiles.html)
- [iTerm2 Scripts and Automation](https://iterm2.com/python-api/)

## 📞 Support

If you encounter issues with iTerm2 configuration:

1. Check this guide's troubleshooting section
2. Verify iTerm2 is properly installed
3. Check file permissions and locations
4. Restart iTerm2 after making changes
5. Open an issue in the dotfiles repository if needed
